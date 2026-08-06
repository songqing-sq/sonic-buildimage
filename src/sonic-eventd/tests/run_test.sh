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
# Usage: run_test.sh <test-binary> [args...]
set -eu

binary="$1"
shift

# Bazel exports RUNFILES_DIR and TEST_TMPDIR for tests; fall back to the
# <binary>.runfiles convention so the wrapper also works when run by hand.
runfiles="${RUNFILES_DIR:-${binary}.runfiles}"
workdir="${TEST_TMPDIR:-$(mktemp -d)}"

libpath=""

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
fi

if [ -n "$libpath" ]; then
    LD_LIBRARY_PATH="${libpath}${LD_LIBRARY_PATH:-}"
    export LD_LIBRARY_PATH
fi

exec "$binary" "$@"
