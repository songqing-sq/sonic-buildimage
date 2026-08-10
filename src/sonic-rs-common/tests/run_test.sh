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

# Deliberately not exported: the trixie glibc this points at may be older than
# the host's, so the coreutils the wrapper itself calls would fail to resolve
# their own GLIBC_ symbol versions against it. Applied per child instead.
if [ -n "$loader" ]; then
    exec env LD_LIBRARY_PATH="$libpath" "$loader" "$binary" "$@"
fi
exec env LD_LIBRARY_PATH="$libpath" "$binary" "$@"
