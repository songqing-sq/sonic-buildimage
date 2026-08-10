#!/bin/sh
# Make the sandboxed gtest binary runnable: resolve its shared-library closure
# and run it against a self-consistent glibc.
#
# Everything here exists only because of `bazel test`; none of it is needed in
# production, where the binary lands in an image that has the deb Depends
# installed into the standard multiarch dirs.
#
# 1. soname vs filename. sonic_shared_library_versioned names the real artifact
#    after the full version (libswsscommon.so.0.0.0) while its SONAME -- hence
#    the DT_NEEDED entry consumers record -- is the major soname
#    (libswsscommon.so.0). cc_shared_library stages only the fully versioned file
#    into the _solib_* dir the link-time RPATH points at; the soname symlink is a
#    separate output, contributed by the library's `_files` target, and lands in
#    the runfiles repo directory.
#
# 2. apt-provided transitive libs. The sandbox has no installed debs at all, so
#    the apt `:data` tars are shipped as test data and unpacked here into a
#    throwaway rootfs.
#
# 3. interpreter vs libc. Once (2) is in place the binary resolves libc.so.6 out
#    of the trixie apt closure, but PT_INTERP still names the absolute path
#    /lib64/ld-linux-x86-64.so.2, i.e. whatever glibc the developer host happens
#    to run. ld.so and libc talk over a private, version-locked ABI
#    (__libc_early_init and friends), so mixing them crashes with a SIGSEGV at a
#    garbage PC before main() ever runs. Invoking the trixie ld-linux explicitly
#    keeps both halves of glibc from the same package.
#
# 4. the hardcoded SonicDBConfig path. The RebootBE / RebootThread fixtures
#    construct swss::DBConnector directly, and SonicDBConfig falls back to the
#    absolute DEFAULT_SONIC_DB_CONFIG_FILE
#    (/var/run/redis/sonic-db/database_config.json) when nothing has initialised
#    it. That path is not writable in the sandbox and swsscommon exposes no
#    env-var override, so the config is staged into TEST_TMPDIR and bind-mounted
#    into place with bubblewrap. /var/run is a symlink to /run, so the bind
#    target is /run/redis.
#
# Usage: run_test.sh <test-binary> [args...]
set -eu

binary="$1"
shift

# Bazel exports RUNFILES_DIR and TEST_TMPDIR for tests; fall back to the
# <binary>.runfiles convention so the wrapper also works when run by hand.
runfiles="${RUNFILES_DIR:-${binary}.runfiles}"
workdir="${TEST_TMPDIR:-$(mktemp -d)}"

[ -d "$runfiles" ] && runfiles=$(cd "$runfiles" && pwd)
[ -d "$workdir" ] && workdir=$(cd "$workdir" && pwd)
binary=$(cd "$(dirname "$binary")" && pwd)/$(basename "$binary")

libpath=""
loader=""
sysroot="$workdir/sysroot"

if [ -d "$runfiles" ]; then
    # --- 1. soname symlinks contributed by the libraries' _files targets ---
    # Depth 3 rather than 2 because some _files targets stage into a subdirectory
    # of their repo dir (libprotobuf lands at sonic-build-infra+/protobuf/). It
    # still stays clear of the _solib_* trees, whose files sit at depth 4 and
    # hold only fully versioned names.
    for dir in $(find "$runfiles" -maxdepth 3 -name '*.so.[0-9]*' -type l 2>/dev/null |
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
    for dir in $(find "$sysroot" -name '*.so.*' 2>/dev/null |
        while IFS= read -r so; do dirname "$so"; done | sort -u); do
        libpath="${libpath}${dir}:"
    done

    # --- 3. the loader that belongs to the libc we are about to load ---
    # Bazel materialises runfiles entries as symlinks, so do not filter -type f.
    loader=$(find "$runfiles" -name 'ld-linux-*.so.*' 2>/dev/null | head -1)
    [ -n "$loader" ] || loader=$(find "$sysroot" -name 'ld-linux-*.so.*' 2>/dev/null | head -1)
fi

# --- 4. a writable /run/redis holding the SonicDBConfig fixture ---
# swsscommon's own database_config.json travels with its runfiles; find it rather
# than hardcoding a canonical repo name.
dbcfg=$(find "$runfiles" -maxdepth 3 -name 'database_config.json' 2>/dev/null | head -1)
bwrap=$(find "$sysroot" -name 'bwrap' -type f 2>/dev/null | head -1)

if [ -n "$dbcfg" ] && [ -n "$bwrap" ]; then
    mkdir -p "$workdir/sonic-db"
    cp "$dbcfg" "$workdir/sonic-db/database_config.json"
    # /var/run is a symlink to /run, so bind the real path. --dev-bind / /
    # keeps everything else visible; only /run gets a fresh tmpfs so the bind
    # target can be created.
    #
    # bwrap is itself a trixie binary, so it needs the trixie libs -- but
    # LD_LIBRARY_PATH must not be *inherited* by the processes it spawns, or
    # every one of them hits the loader/libc mismatch from (3). So drive bwrap
    # through the loader's explicit --library-path (which does not propagate) and
    # set LD_LIBRARY_PATH only for the test binary, inside the sandbox.
    bwrap_libs=$(find "$sysroot" -name 'libcap.so.*' -o -name 'libselinux.so.*' 2>/dev/null |
        while IFS= read -r so; do dirname "$so"; done | sort -u | tr '\n' ':')
    exec "$loader" --library-path "${bwrap_libs}${libpath}" "$bwrap" \
        --dev-bind / / \
        --tmpfs /run \
        --bind "$workdir/sonic-db" /run/redis/sonic-db \
        -- env LD_LIBRARY_PATH="$libpath" ${loader:+"$loader"} "$binary" "$@"
fi

# Deliberately not exported: the trixie glibc this points at may be older than
# the host's, so the coreutils the wrapper itself calls would fail to resolve
# their own GLIBC_ symbol versions against it. Applied per child instead.
if [ -n "$loader" ]; then
    exec env LD_LIBRARY_PATH="$libpath" "$loader" "$binary" "$@"
fi
exec env LD_LIBRARY_PATH="$libpath" "$binary" "$@"
