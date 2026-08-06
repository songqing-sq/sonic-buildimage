#!/bin/sh
# Make a sandboxed gtest binary runnable: resolve its shared-library closure,
# put it in the working directory its fixtures are written against, and -- when
# asked -- give it a redis to talk to.
#
# Everything here exists only because of `bazel test`; none of it is needed in
# production, where the binaries land in a docker image that has the deb
# Depends installed into the standard multiarch dirs.
#
# 1. soname vs filename. sonic_shared_library_versioned names the real artifact
#    after the full version (libswsscommon.so.0.0.0) while its SONAME -- hence
#    the DT_NEEDED entry consumers record -- is the major soname
#    (libswsscommon.so.0). cc_shared_library stages only the fully versioned file
#    into the _solib_* dir the link-time RPATH points at; the soname symlink is a
#    separate output, contributed by the library's `_files` target, and lands in
#    the runfiles repo directory. Scanning for those symlinks and adding their
#    directories to LD_LIBRARY_PATH avoids hardcoding canonical repo names into
#    linkopts. (Nothing has to be recreated here: `_files` carries the symlink,
#    just as a Debian library package ships its own as a real archive member.)
#
# 2. apt-provided transitive libs. The sandbox has no installed debs at all, so
#    the apt `:data` tars are shipped as test data and unpacked here into a
#    throwaway rootfs.
#
# 3. interpreter vs libc. Once (2) is in place the binary resolves libc.so.6 out
#    of the trixie apt closure (glibc 2.41), but PT_INTERP still names the
#    absolute path /lib64/ld-linux-x86-64.so.2, i.e. whatever glibc the developer
#    host happens to run. ld.so and libc talk over a private, version-locked ABI
#    (__libc_early_init and friends), so mixing them crashes with a SIGSEGV at a
#    garbage PC before main() ever runs. Invoking the trixie ld-linux explicitly
#    keeps both halves of glibc from the same package.
#
# 4. redis. The DB-backed cases need a live server. There is no /var/run/redis
#    to bind a socket in and port 6379 may belong to the developer's own redis,
#    so the fixture jsons are re-emitted with both endpoints rewritten and a
#    private redis-server is started on them. The tests reach the same instance
#    over TCP (DBConnector isTcpConn=true) and over the unix socket
#    (stats_collector uses isTcpConn=false), which is why both have to move
#    together. The socket itself cannot live under TEST_TMPDIR: sun_path is
#    108 bytes and the sandbox path alone is longer than that.
#
# Usage: run_test.sh [--redis] <test-binary> [args...]
set -eu

want_redis=0
if [ "${1:-}" = "--redis" ]; then
    want_redis=1
    shift
fi

binary="$1"
shift

# Bazel exports RUNFILES_DIR and TEST_TMPDIR for tests; fall back to the
# <binary>.runfiles convention so the wrapper also works when run by hand.
runfiles="${RUNFILES_DIR:-${binary}.runfiles}"
workdir="${TEST_TMPDIR:-$(mktemp -d)}"

# Everything collected below ends up in LD_LIBRARY_PATH, and the wrapper cd's
# elsewhere before exec'ing, so these have to be absolute.
[ -d "$runfiles" ] && runfiles=$(cd "$runfiles" && pwd)
[ -d "$workdir" ] && workdir=$(cd "$workdir" && pwd)
binary=$(cd "$(dirname "$binary")" && pwd)/$(basename "$binary")

libpath=""
loader=""
sysroot="$workdir/sysroot"

# --- 1. soname symlinks contributed by the sonic libraries' _files targets ---
if [ -d "$runfiles" ]; then
    # -maxdepth 2 keeps the scan on the per-repo directories and skips the
    # _solib_* trees, which hold only fully versioned files.
    for dir in $(find "$runfiles" -maxdepth 2 -name '*.so.[0-9]*' -type l 2>/dev/null |
        while IFS= read -r link; do dirname "$link"; done | sort -u); do
        libpath="${libpath}${dir}:"
    done

    # --- 2. unpack the apt data tars into a minimal rootfs ---
    mkdir -p "$sysroot"
    # rules_distroless stages an apt package's `:data` as content.tar.gz; accept
    # the data.tar* spelling too so the wrapper is not tied to that detail.
    for tarball in $(find "$runfiles" \( -name 'content.tar*' -o -name 'data.tar*' \) 2>/dev/null); do
        tar -xf "$tarball" -C "$sysroot" 2>/dev/null || true
    done

    # Add every directory that ended up holding shared objects.
    for dir in $(find "$sysroot" -name '*.so.*' 2>/dev/null |
        while IFS= read -r so; do dirname "$so"; done | sort -u); do
        libpath="${libpath}${dir}:"
    done

    # --- 3. the loader that belongs to the libc we are about to load ---
    # libc6's :data ships it too, but the _solib_* copy is the one
    # cc_shared_library already stages next to libc.so.6, so prefer it.
    # Bazel materialises runfiles entries as symlinks, so do not filter on -type f.
    loader=$(find "$runfiles" -name 'ld-linux-*.so.*' 2>/dev/null | head -1)
    [ -n "$loader" ] || loader=$(find "$sysroot" -name 'ld-linux-*.so.*' 2>/dev/null | head -1)

    # The cc_binary reaches the _solib_* dirs through its link-time RPATH, but a
    # prebuilt deb binary like redis-server has no RPATH, so it would fall back
    # to the host's libstdc++/libssl and crash once mixed with the trixie ld.so.
    for dir in $(find "$runfiles" -path '*_solib_*' -name 'lib*.so.*' 2>/dev/null |
        while IFS= read -r so; do dirname "$so"; done | sort -u); do
        libpath="${libpath}${dir}:"
    done
fi

# Deliberately not exported: the trixie glibc this points at is older than the
# host's, so the coreutils the wrapper itself calls (dirname, sed, find) would
# fail to resolve their own GLIBC_ symbol versions against it. run() applies it
# per child instead, so only the binaries launched under the trixie loader see it.
run() {
    if [ -n "$loader" ]; then
        env LD_LIBRARY_PATH="$libpath" "$loader" "$@"
    else
        env LD_LIBRARY_PATH="$libpath" "$@"
    fi
}

# The gtest sources address their fixtures relative to the working directory
# (./tests/..., ./rsyslog_plugin_tests/...), rooted at the package dir. A
# sh_test starts at the runfiles root instead, so move into the runfiles
# directory of the repo that owns the binary.
rundir=$(dirname "$binary")

# --- 4. a private redis on rewritten endpoints ---
if [ "$want_redis" = 1 ]; then
    # sockaddr_un.sun_path holds only 108 bytes and the sandboxed TEST_TMPDIR
    # path alone is longer than that, so the socket needs a short home of its own.
    sockdir=$(mktemp -d)
    sock="$sockdir/r.sock"
    mkdir -p "$workdir/redis-data"

    # Probing for a free port and then binding it is racy -- parallel eventd
    # tests did collide -- so just let redis tell us and retry on another port.
    # Seed from the pid, since two tests can start in the same wall-clock second.
    port=$(awk -v s="$$" 'BEGIN{srand(s);print 20000+int(rand()*20000)}')
    ready=0
    attempt=0
    while [ "$attempt" -lt 20 ]; do
        attempt=$((attempt + 1))
        # --save '' / --appendonly no keep it purely in-memory; there is nothing
        # to persist between test runs.
        run "$sysroot/usr/bin/redis-server" \
            --port "$port" \
            --unixsocket "$sock" \
            --bind 127.0.0.1 \
            --save '' \
            --appendonly no \
            --dir "$workdir/redis-data" >"$workdir/redis.log" 2>&1 &
        redis_pid=$!
        trap 'kill "$redis_pid" 2>/dev/null || true; rm -rf "$sockdir"' EXIT INT TERM

        for _ in $(seq 1 80); do
            if run "$sysroot/usr/bin/redis-cli" -s "$sock" ping 2>/dev/null | grep -q PONG; then
                ready=1
                break
            fi
            kill -0 "$redis_pid" 2>/dev/null || break
            sleep 0.25
        done
        [ "$ready" = 1 ] && break

        kill "$redis_pid" 2>/dev/null || true
        grep -q 'Address already in use' "$workdir/redis.log" || break
        port=$((port + 1))
    done
    if [ "$ready" != 1 ]; then
        echo "run_test.sh: redis-server did not come up; log follows" >&2
        cat "$workdir/redis.log" >&2
        exit 1
    fi

    # Mirror the package dir into TEST_TMPDIR so the fixtures become writable:
    # symlink every file, then replace the db config jsons with copies pointing
    # at the endpoints redis actually bound. The runfiles tree is read-only, and
    # this has to happen after the retry loop settles on a port.
    mirror="$workdir/rundir"
    mkdir -p "$mirror"
    (cd "$rundir" && find . -type d) | while IFS= read -r d; do
        mkdir -p "$mirror/$d"
    done
    (cd "$rundir" && find . ! -type d) | while IFS= read -r f; do
        ln -sf "$rundir/${f#./}" "$mirror/$f"
    done
    for cfg in $(find "$rundir" -name '*.json' 2>/dev/null); do
        grep -q unix_socket_path "$cfg" || continue
        rel=${cfg#"$rundir"/}
        rm -f "$mirror/$rel"
        sed -e "s#\"unix_socket_path\"[[:space:]]*:[[:space:]]*\"[^\"]*\"#\"unix_socket_path\": \"$sock\"#g" \
            -e "s#\"port\"[[:space:]]*:[[:space:]]*[0-9]*#\"port\": $port#g" \
            "$cfg" > "$mirror/$rel"
    done
    rundir="$mirror"
fi

cd "$rundir"
run "$binary" "$@"
