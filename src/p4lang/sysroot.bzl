"""Build a complete Debian sysroot directory from rules_distroless apt package
content tarballs, plus a LD_LIBRARY_PATH-safe lib directory.

rules_distroless' set-level `//:directory` (merge_directory) only exposes the
cc-oriented header/lib symlinks, not the tool binaries (autoreconf, protoc,
pkgconf, ...) needed to drive an autotools/cmake build. However each package's
aggregate filegroup `@set//<pkg>:<pkg>` expands to the `content.tar.gz` of that
package's full dependency closure. `deb_sysroot` extracts a union of such
tarballs into a single TreeArtifact -- a real rootfs with usr/bin, usr/share,
usr/lib, pkgconfig, etc.
"""

def _deb_sysroot_impl(ctx):
    tars = []
    for t in ctx.attr.tars:
        tars.extend(t[DefaultInfo].files.to_list())

    # De-duplicate (aggregate filegroups overlap heavily in their closures).
    seen = {}
    uniq = []
    for f in tars:
        if f.path not in seen:
            seen[f.path] = True
            uniq.append(f)

    out = ctx.actions.declare_directory(ctx.label.name)
    args = ctx.actions.args()
    args.add(out.path)
    args.add_all(uniq)
    ctx.actions.run_shell(
        inputs = uniq,
        outputs = [out],
        arguments = [args],
        command = """
set -eu
OUT="$1"; shift
mkdir -p "$OUT"
for t in "$@"; do
  tar -xzf "$t" -C "$OUT" 2>/dev/null || tar -xf "$t" -C "$OUT"
done
# Recreate the unversioned automake/aclocal names that dpkg's update-alternatives
# would normally symlink in postinst (we do not run maintainer scripts). autoreconf
# invokes `automake`/`aclocal` by their unversioned names.
bindir="$OUT/usr/bin"
if [ -d "$bindir" ]; then
  for base in automake aclocal; do
    if [ ! -e "$bindir/$base" ]; then
      v=$(ls "$bindir" 2>/dev/null | grep -E "^${base}-[0-9]" | sort -V | tail -1 || true)
      [ -n "$v" ] && ln -sf "$v" "$bindir/$base" || true
    fi
  done
  # Debian's autom4te only searches the absolute /usr/share/autoconf baked into
  # autom4te.cfg (--prepend-include), which is empty in a relocated sysroot.
  # Patch it to also search $pkgdatadir (honours the AC_MACRODIR env var) so the
  # autoconf macro library is found under the sysroot path.
  if [ -f "$bindir/autom4te" ]; then
    sed -i '/uniq (reverse(@prepend_include), @include)/a unshift @include, $pkgdatadir if $pkgdatadir;' "$bindir/autom4te" || true
  fi
  # libtoolize bakes absolute /usr paths for its aux/macro dirs (Debian installed
  # layout: build-aux under usr/share/libtool, macros under usr/share/aclocal).
  # Rewrite those five assignments to honour a ${LT_SYSROOT_PREFIX} env var so the
  # relocated sysroot is used, without triggering _lt_pkgdatadir source-mode
  # (which would demand a full libltdl source tree PI never needs).
  if [ -f "$bindir/libtoolize" ]; then
    sed -i \
      -e 's#prefix="/usr"#prefix="${LT_SYSROOT_PREFIX}/usr"#' \
      -e 's#datadir="/usr/share"#datadir="${LT_SYSROOT_PREFIX}/usr/share"#' \
      -e 's#pkgauxdir="/usr/share/libtool/build-aux"#pkgauxdir="${LT_SYSROOT_PREFIX}/usr/share/libtool/build-aux"#' \
      -e 's#pkgltdldir="/usr/share/libtool"#pkgltdldir="${LT_SYSROOT_PREFIX}/usr/share/libtool"#' \
      -e 's#aclocaldir="/usr/share/aclocal"#aclocaldir="${LT_SYSROOT_PREFIX}/usr/share/aclocal"#' \
      "$bindir/libtoolize" || true
  fi
fi
""",
        mnemonic = "DebSysroot",
        progress_message = "Extracting %d deb content tarballs into a sysroot" % len(uniq),
    )
    return [DefaultInfo(files = depset([out]))]

deb_sysroot = rule(
    implementation = _deb_sysroot_impl,
    attrs = {
        "tars": attr.label_list(
            mandatory = True,
            doc = "Aggregate filegroups (@set//<pkg>:<pkg>) of content.tar.gz.",
        ),
    },
)

def _filtered_libdir_impl(ctx):
    dirs = [f for f in ctx.attr.src[DefaultInfo].files.to_list() if f.is_directory]
    if len(dirs) != 1:
        fail("expected exactly one directory artifact, got {}".format(len(dirs)))
    sysroot = dirs[0]
    out = ctx.actions.declare_directory(ctx.label.name)

    # Copy every shared object from the sysroot's multiarch lib dirs EXCEPT the
    # core glibc/loader libraries. Exposing this dir on LD_LIBRARY_PATH then lets
    # tools (protoc, pkgconf, ...) find libprotoc/libprotobuf/libgrpc/libabsl/...
    # while host coreutils keep using the newer host glibc (trixie is 2.41, the
    # Ubuntu build host is 2.43 -- shadowing libc.so.6 would break `touch`/`cat`).
    exclude = "libc.so libc- libm.so libm- libmvec libpthread libdl.so librt.so libresolv libnss libnsl ld-linux ld.so libcrypt.so libutil libanl libBrokenLocale libthread_db"
    ctx.actions.run_shell(
        inputs = [sysroot],
        outputs = [out],
        command = """
set -eu
SR="$1"; OUT="$2"; EXCL="$3"
mkdir -p "$OUT"
for d in "$SR/usr/lib/x86_64-linux-gnu" "$SR/lib/x86_64-linux-gnu"; do
  [ -d "$d" ] || continue
  for f in "$d"/*.so*; do
    [ -e "$f" ] || continue
    b=$(basename "$f")
    skip=0
    for pat in $EXCL; do
      case "$b" in ${pat}*) skip=1; break;; esac
    done
    [ "$skip" = 1 ] && continue
    cp -aL "$f" "$OUT/$b" 2>/dev/null || true
  done
done
""",
        arguments = [sysroot.path, out.path, exclude],
        mnemonic = "FilterSysrootLibs",
    )
    return [DefaultInfo(files = depset([out]))]

filtered_libdir = rule(
    implementation = _filtered_libdir_impl,
    attrs = {
        "src": attr.label(mandatory = True),
    },
)

def _deb_data_tar_impl(ctx):
    dirs = [f for f in ctx.attr.gendir[DefaultInfo].files.to_list() if f.is_directory]
    if len(dirs) != 1:
        fail("expected exactly one directory artifact, got {}".format(len(dirs)))
    gendir = dirs[0]
    out = ctx.actions.declare_file(ctx.label.name + ".tar.gz")
    ctx.actions.run_shell(
        inputs = [gendir],
        outputs = [out],
        command = """
set -eu
GEN="$1"; OUT="$2"
STAGE=$(mktemp -d)
trap 'rm -rf "$STAGE"' EXIT
mkdir -p "$STAGE/usr/bin" "$STAGE/usr/lib/x86_64-linux-gnu" "$STAGE/usr/include" "$STAGE/usr/lib/python3/dist-packages"
[ -d "$GEN/bin" ]     && cp -aL "$GEN/bin/."     "$STAGE/usr/bin/" 2>/dev/null || true
[ -d "$GEN/lib" ]     && for f in "$GEN"/lib/*; do [ -f "$f" ] && cp -aL "$f" "$STAGE/usr/lib/x86_64-linux-gnu/"; done || true
[ -d "$GEN/include" ] && cp -aL "$GEN/include/." "$STAGE/usr/include/" 2>/dev/null || true
# Python protobuf/grpc bindings: python*/site-packages -> dist-packages.
for pd in "$GEN"/lib/python*/site-packages "$GEN"/python*/site-packages; do
  [ -d "$pd" ] && cp -aL "$pd/." "$STAGE/usr/lib/python3/dist-packages/" 2>/dev/null || true
done
# Drop empty staged dirs so the tar mirrors the Make deb's populated set only.
find "$STAGE" -type d -empty -delete 2>/dev/null || true
tar --sort=name --owner=0 --group=0 --numeric-owner --mtime='@0' \
    -czf "$OUT" -C "$STAGE" ./ 2>/dev/null || tar -czf "$OUT" -C "$STAGE" ./
""",
        arguments = [gendir.path, out.path],
        mnemonic = "DebDataTar",
        progress_message = "Building Debian data.tar.gz for %s" % ctx.label.name,
    )
    return [DefaultInfo(files = depset([out]))]

deb_data_tar = rule(
    implementation = _deb_data_tar_impl,
    attrs = {
        "gendir": attr.label(mandatory = True),
    },
)
