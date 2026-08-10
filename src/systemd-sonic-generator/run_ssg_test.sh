#!/bin/bash
# Bazel test launcher for ssg_test, following sonic-eventd's
# tests/run_test.sh approach (minus its redis and bazel-built-.so parts,
# which ssg does not need). Two gaps between `bazel test` and the Make-side
# `make test` environment are bridged here:
#
# 1. Fixtures. ssg-test.cc addresses its data via CWD-relative paths
#    (tests/testfiles/ inputs, tests/ssg-test/ scratch tree) because Make
#    runs it from the package root. The bazel CWD is the main repo's
#    runfiles dir, so the fixtures are staged into a writable TEST_TMPDIR
#    tree and the binary runs from there.
#
# 2. Dynamic libraries. The binary is dynamically linked against the trixie
#    boost/json-c .so (matching Make), but the sandbox has no installed debs
#    and the toolchain writes no usable RUNPATH. The runtime deb :data tars
#    (declared as TEST_APT_DATA in BUILD.bazel) are unpacked into a sysroot
#    served via LD_LIBRARY_PATH. The binary is started under the trixie
#    ld-linux from that same sysroot: ld.so and libc speak a private,
#    version-locked ABI, so the loader, libc, libm and libstdc++ must all
#    come from one glibc generation — mixing with the host's crashes
#    (GLIBC_ABI_DT_X86_64_PLT / SIGSEGV before main).
#
# LD_LIBRARY_PATH is passed only to the test process (via exec env), never
# exported to this script itself, so the host coreutils the wrapper calls
# keep resolving against the host glibc.
set -euo pipefail

# Resolve everything to absolute paths before cd'ing away. The SSG_* values
# are $(rootpath)s injected by the sh_test env attr, relative to the CWD
# (runfiles/_main). RUNFILES_DIR is exported by bazel for tests; fall back
# to the parent of the CWD, which is the runfiles root.
BIN="$PWD/$SSG_TEST_BIN"
TESTFILES_DIR="$PWD/$(dirname "$SSG_TESTFILE")"
RUNFILES="${RUNFILES_DIR:-$PWD/..}"
TMP="${TEST_TMPDIR:-$(mktemp -d)}"

# --- 1. stage the fixtures into a writable package-root replica ---
WORK="$TMP/ssg_work"
mkdir -p "$WORK/tests"
cp -rL "$TESTFILES_DIR" "$WORK/tests/"

# --- 2. unpack the runtime deb payloads into a sysroot ---
# rules_distroless stages an apt package's :data as content.tar.gz; accept
# the data.tar* spelling too so this is not tied to that detail.
SYSROOT="$TMP/sysroot"
mkdir -p "$SYSROOT"
for tarball in $(find -L "$RUNFILES" \( -name 'content.tar*' -o -name 'data.tar*' \) 2>/dev/null); do
    tar -xf "$tarball" -C "$SYSROOT" 2>/dev/null || true
done

# Every directory that ended up holding shared objects joins the search path.
libpath=""
for dir in $(find "$SYSROOT" -name '*.so.*' 2>/dev/null |
    while IFS= read -r so; do dirname "$so"; done | sort -u); do
    libpath="${libpath}${dir}:"
done

# --- 3. the loader that belongs to the libc we are about to load ---
loader=$(find "$SYSROOT" -name 'ld-linux-*.so.*' -type f 2>/dev/null | head -1)

cd "$WORK"
if [ -n "$loader" ]; then
    exec env LD_LIBRARY_PATH="$libpath" "$loader" "$BIN" "$@"
else
    # No glibc in the sysroot (data tars trimmed?) — fall back to the host
    # loader; the boost/json-c NEEDED still resolve from LD_LIBRARY_PATH.
    exec env LD_LIBRARY_PATH="$libpath" "$BIN" "$@"
fi
