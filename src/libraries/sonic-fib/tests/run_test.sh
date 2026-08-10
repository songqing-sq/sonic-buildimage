#!/bin/sh
# Make the sandboxed gtest binary able to resolve libnexthopgroup.
#
# sonic_shared_library_versioned names the real artifact after the full version
# (libnexthopgroup.so.0.0.0) while its SONAME -- hence the DT_NEEDED entry the
# test binary records -- is the major soname (libnexthopgroup.so.0).
# cc_shared_library stages only the fully versioned file into the _solib_* dir
# the link-time RPATH points at; the soname symlink is a separate output carried
# by the library's `_files` target and lands in the runfiles repo directory.
# Scanning for those symlinks and adding their directories to LD_LIBRARY_PATH
# avoids hardcoding canonical repo names into linkopts.
#
# Unlike sonic-eventd's wrapper there is nothing else to do here: libnexthopgroup
# links only libpthread, so no apt runtime closure has to be staged, and with no
# hermetic libc in play the default interpreter and libc stay consistent.
#
# Usage: run_test.sh <test-binary> [args...]
set -eu

binary="$1"
shift

# Bazel exports RUNFILES_DIR for tests; fall back to the <binary>.runfiles
# convention so the wrapper also works when run by hand.
runfiles="${RUNFILES_DIR:-${binary}.runfiles}"

[ -d "$runfiles" ] && runfiles=$(cd "$runfiles" && pwd)
binary=$(cd "$(dirname "$binary")" && pwd)/$(basename "$binary")

libpath=""
if [ -d "$runfiles" ]; then
    # -maxdepth 2 keeps the scan on the per-repo directories and skips the
    # _solib_* trees, which hold only fully versioned files.
    for dir in $(find "$runfiles" -maxdepth 2 -name '*.so.[0-9]*' -type l 2>/dev/null |
        while IFS= read -r link; do dirname "$link"; done | sort -u); do
        libpath="${libpath}${dir}:"
    done
fi

LD_LIBRARY_PATH="${libpath}${LD_LIBRARY_PATH:-}"
export LD_LIBRARY_PATH

exec "$binary" "$@"
