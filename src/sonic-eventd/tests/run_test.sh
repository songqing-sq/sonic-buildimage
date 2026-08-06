#!/bin/sh
# Make a sandboxed cc_test's shared-library closure resolvable.
#
# Two separate problems have to be solved, both of which only show up under
# `bazel test` and never in production:
#
# 1. soname vs filename. sonic_shared_library_versioned names the real artifact
#    after the full version (libswsscommon.so.0.0.0) while its SONAME -- hence
#    the DT_NEEDED entry consumers record -- is the major soname
#    (libswsscommon.so.0). cc_shared_library only stages the fully versioned
#    file into the _solib_* dir the link-time RPATH points at; the soname symlink
#    comes from the library's separate `_files` target and lands in the runfiles
#    repo directory. Scanning for those symlinks and adding their directories to
#    LD_LIBRARY_PATH avoids hardcoding canonical repo names into linkopts.
#
# 2. apt-provided transitive libs. The production binaries land in a docker image
#    where libswsscommon's deb Depends install libzmq5, libhiredis, boost,
#    libuuid, ... into the standard multiarch dir, so ld.so finds them with no
#    RPATH at all. The sandbox has none of that, so the apt `:data` tars are
#    shipped as test data and unpacked here into a throwaway rootfs.
#
# 3. interpreter vs libc. Once (2) is in place the binary resolves libc.so.6 out
#    of the trixie apt closure (glibc 2.41), but PT_INTERP still names the
#    absolute path /lib64/ld-linux-x86-64.so.2, i.e. whatever glibc the developer
#    host happens to run. ld.so and libc talk over a private, version-locked ABI
#    (__libc_early_init and friends), so mixing them crashes with a SIGSEGV at a
#    garbage PC before main() ever runs. Invoking the trixie ld-linux explicitly
#    keeps both halves of glibc from the same package.
#
# Usage: run_test.sh <test-binary> [args...]
set -eu

binary="$1"
shift

# Bazel exports RUNFILES_DIR and TEST_TMPDIR for tests; fall back to the
# <binary>.runfiles convention so the wrapper also works when run by hand.
runfiles="${RUNFILES_DIR:-${binary}.runfiles}"
workdir="${TEST_TMPDIR:-$(mktemp -d)}"

# Everything collected below ends up in LD_LIBRARY_PATH, and the wrapper cd's
# into the fixture directory before exec'ing, so these have to be absolute.
[ -d "$runfiles" ] && runfiles=$(cd "$runfiles" && pwd)
[ -d "$workdir" ] && workdir=$(cd "$workdir" && pwd)

libpath=""
loader=""

# --- 1. soname symlinks contributed by the sonic libraries' _files targets ---
if [ -d "$runfiles" ]; then
    # -maxdepth 2 keeps the scan on the per-repo directories and skips the
    # _solib_* trees, which hold only fully versioned files.
    for dir in $(find "$runfiles" -maxdepth 2 -name '*.so.[0-9]*' -type l 2>/dev/null |
        while IFS= read -r link; do dirname "$link"; done | sort -u); do
        libpath="${libpath}${dir}:"
    done

    # --- 2. unpack the apt data tars into a minimal rootfs ---
    sysroot="$workdir/sysroot"
    mkdir -p "$sysroot"
    # rules_distroless stages an apt package's `:data` as content.tar.gz; accept
    # the data.tar* spelling too so the wrapper is not tied to that detail.
    for tarball in $(find "$runfiles" \( -name 'content.tar*' -o -name 'data.tar*' \) 2>/dev/null); do
        tar -xf "$tarball" -C "$sysroot" 2>/dev/null || true
    done

    # A deb only ships the fully versioned file (liblua5.1.so.0.0.0); the soname
    # symlink (liblua5.1.so.0) is created on the target by ldconfig from the
    # package's postinst and is therefore absent here. Recreate it by reading
    # each library's SONAME -- this is what ldconfig would have done.
    for so in $(find "$sysroot" -name '*.so.*' -type f 2>/dev/null); do
        soname=$(readelf -d "$so" 2>/dev/null |
            sed -n 's/.*SONAME.*\[\(.*\)\].*/\1/p' | head -1)
        [ -n "$soname" ] || continue
        link="$(dirname "$so")/$soname"
        [ -e "$link" ] || ln -s "$(basename "$so")" "$link" 2>/dev/null || true
    done
    # Add every directory that ended up holding shared objects.
    for dir in $(find "$sysroot" -name '*.so.*' 2>/dev/null |
        while IFS= read -r so; do dirname "$so"; done | sort -u); do
        libpath="${libpath}${dir}:"
    done

    # --- 3. the loader that belongs to the libc we are about to load ---
    # libc6's :data ships it too, but the _solib_* copy is the one cc_shared_library
    # already stages next to libc.so.6, so prefer it and fall back to the sysroot.
    # Bazel materialises runfiles entries as symlinks, so do not filter on -type f.
    loader=$(find "$runfiles" -name 'ld-linux-*.so.*' 2>/dev/null | head -1)
    [ -n "$loader" ] || loader=$(find "$sysroot" -name 'ld-linux-*.so.*' 2>/dev/null | head -1)
fi

if [ -n "$libpath" ]; then
    LD_LIBRARY_PATH="${libpath}${LD_LIBRARY_PATH:-}"
    export LD_LIBRARY_PATH
fi

# main.cpp loads its SonicDBConfig fixtures through paths relative to the working
# directory (./tests/redis_multi_db_ut_config/database_{config,global}.json), but
# a sh_test starts at the runfiles root while the fixtures sit under
# runfiles/<repo>/tests/. Without this the config never loads and the suite
# segfaults. Locate the directory that owns the fixture dir instead of
# hardcoding the canonical repo name.
binary=$(cd "$(dirname "$binary")" && pwd)/$(basename "$binary")
fixture_parent=$(find "${runfiles:-.}" -maxdepth 3 -type d \
    -path '*/tests/redis_multi_db_ut_config' 2>/dev/null | head -1)
if [ -n "$fixture_parent" ]; then
    cd "${fixture_parent%/tests/redis_multi_db_ut_config}"
fi

if [ -n "$loader" ]; then
    exec "$loader" "$binary" "$@"
fi
exec "$binary" "$@"
