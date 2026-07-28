"""Source-file exposure for the bash 5.2.37 tarball.

The tarball ships no BUILD file, so this one is injected via
`http_archive(build_file = ...)`. It only exposes file groups — all compilation
happens in //:BUILD.bazel of the bash module, which has the generated
config.h/pathnames.h/version.h checked in.
"""

load("@rules_cc//cc:cc_library.bzl", "cc_library")

package(default_visibility = ["//visibility:public"])

# Bash's headers, exposed as a cc_library so the -I paths land on THIS repo's
# root. Defining it in the bash module instead would point the include path at
# that module's root, where the headers do not live.
#
# The .c files include these unqualified ("shell.h"), with a subdir
# ("builtins/common.h"), or via <readline/readline.h>, all of which resolve from
# the tarball root plus lib/.
cc_library(
    name = "bash_hdrs",
    hdrs = glob(
        [
            "*.h",
            "include/*.h",
            "builtins/*.h",
            "lib/**/*.h",
        ],
        allow_empty = False,
    ),
    includes = [
        ".",
        # The .def-generated builtins include "common.h" / "bashgetopt.h"
        # unqualified, expecting builtins/ itself on the path.
        "builtins",
        "include",
        "lib",
        "lib/readline",
    ],
)

# Bash's own headers, consumed with plain `#include "x.h"` from the top of the
# tree. include_prefix/strip_include_prefix is not used: the .c files expect
# these to resolve relative to the source root.
filegroup(
    name = "top_hdrs",
    srcs = glob(
        [
            "*.h",
            "include/*.h",
            "builtins/*.h",
            "lib/**/*.h",
        ],
        allow_empty = False,
    ),
)

# The shell core (Makefile.in OBJECTS, minus the generated y.tab.c / syntax.c
# and minus version.o which is built from the checked-in version.h).
filegroup(
    name = "shell_srcs",
    srcs = [
        "alias.c",
        "array.c",
        "arrayfunc.c",
        "assoc.c",
        "bashhist.c",
        "bashline.c",
        "braces.c",
        "bracecomp.c",
        "copy_cmd.c",
        "dispose_cmd.c",
        "error.c",
        "eval.c",
        "execute_cmd.c",
        "expr.c",
        "findcmd.c",
        "flags.c",
        "general.c",
        "hashcmd.c",
        "hashlib.c",
        "input.c",
        "jobs.c",
        "list.c",
        "locale.c",
        "mailcheck.c",
        "make_cmd.c",
        "pathexp.c",
        "pcomplete.c",
        "pcomplib.c",
        "plugin.c",
        "print_cmd.c",
        "redir.c",
        "shell.c",
        "sig.c",
        "stringlib.c",
        "subst.c",
        "test.c",
        "trap.c",
        "unwind_prot.c",
        "variables.c",
        "version.c",
        "xmalloc.c",
    ],
)

# Grammar + the mksyntax/mksignames inputs.
exports_files([
    "config.h.in",
    "pathnames.h.in",
    "patchlevel.h",
    "support/mkversion.sh",
    "y.tab.c",
    "y.tab.h",
    "parse.y",
    "mksyntax.c",
    "syntax.h",
    "support/mksignames.c",
    "support/signames.c",
    "builtins/mkbuiltins.c",
])

# builtins/*.def — mkbuiltins turns each into a .c file.
filegroup(
    name = "builtin_defs",
    srcs = glob(
        ["builtins/*.def"],
        allow_empty = False,
    ),
)

# builtins/ hand-written C (Makefile.in BUILTIN_C_OBJ + getopt).
filegroup(
    name = "builtins_c_srcs",
    srcs = [
        "builtins/bashgetopt.c",
        "builtins/common.c",
        "builtins/evalfile.c",
        "builtins/evalstring.c",
        "builtins/getopt.c",
    ],
)

# lib/sh — Makefile.in OBJECTS for libsh.a.
filegroup(
    name = "libsh_srcs",
    srcs = [
        "lib/sh/casemod.c",
        "lib/sh/clktck.c",
        "lib/sh/clock.c",
        "lib/sh/eaccess.c",
        "lib/sh/fmtullong.c",
        "lib/sh/fmtulong.c",
        "lib/sh/fmtumax.c",
        "lib/sh/fnxform.c",
        "lib/sh/fpurge.c",
        "lib/sh/getenv.c",
        "lib/sh/gettimeofday.c",
        "lib/sh/input_avail.c",
        "lib/sh/itos.c",
        "lib/sh/mailstat.c",
        "lib/sh/makepath.c",
        "lib/sh/mbscasecmp.c",
        "lib/sh/mbschr.c",
        "lib/sh/mbscmp.c",
        "lib/sh/netconn.c",
        "lib/sh/netopen.c",
        "lib/sh/oslib.c",
        "lib/sh/pathcanon.c",
        "lib/sh/pathphys.c",
        "lib/sh/random.c",
        "lib/sh/setlinebuf.c",
        "lib/sh/shmatch.c",
        "lib/sh/shmbchar.c",
        "lib/sh/shquote.c",
        "lib/sh/shtty.c",
        "lib/sh/snprintf.c",
        "lib/sh/spell.c",
        "lib/sh/stringlist.c",
        "lib/sh/stringvec.c",
        "lib/sh/strnlen.c",
        "lib/sh/strtrans.c",
        "lib/sh/strvis.c",
        "lib/sh/timers.c",
        "lib/sh/timeval.c",
        "lib/sh/tmpfile.c",
        "lib/sh/uconvert.c",
        "lib/sh/ufuncs.c",
        "lib/sh/unicode.c",
        "lib/sh/utf8.c",
        "lib/sh/wcsdup.c",
        "lib/sh/wcsnwidth.c",
        "lib/sh/winsize.c",
        "lib/sh/zcatfd.c",
        "lib/sh/zgetline.c",
        "lib/sh/zmapfd.c",
        "lib/sh/zread.c",
        "lib/sh/zwrite.c",
    ],
)

# lib/glob — libglob.a. Note gmisc.c and lib/sh/fmtulong.c are BOTH compiled as
# their own translation unit and #included textually by a sibling (verified
# against the .o set and symbol tables of Make's build): gmisc.o exports
# match_pattern_char/umatchlen/..., fmtulong.o exports fmtulong.
filegroup(
    name = "libglob_srcs",
    srcs = [
        "lib/glob/glob.c",
        "lib/glob/gmisc.c",
        "lib/glob/smatch.c",
        "lib/glob/strmatch.c",
        "lib/glob/xmbsrtowcs.c",
    ],
)

filegroup(
    name = "libtilde_srcs",
    srcs = ["lib/tilde/tilde.c"],
)

# lib/readline — bash links its BUNDLED readline (Makefile READLINE_LDFLAGS
# points at lib/readline), not the system one.
#
# lib/readline/shell.c is omitted on purpose. It provides standalone-readline
# fallbacks for sh_get_env_value / sh_get_home_dir / sh_single_quote /
# sh_set_lines_and_columns / sh_unset_nodelay_mode, all of which bash itself
# defines in variables.c and general.c. Make links -lreadline as an archive, so
# ld never pulls shell.o in once those symbols are already resolved; Bazel would
# link every member and hit 5 duplicate-definition errors.
filegroup(
    name = "libreadline_srcs",
    srcs = [
        "lib/readline/bind.c",
        "lib/readline/callback.c",
        "lib/readline/colors.c",
        "lib/readline/compat.c",
        "lib/readline/complete.c",
        "lib/readline/display.c",
        "lib/readline/funmap.c",
        "lib/readline/histexpand.c",
        "lib/readline/histfile.c",
        "lib/readline/history.c",
        "lib/readline/histsearch.c",
        "lib/readline/input.c",
        "lib/readline/isearch.c",
        "lib/readline/keymaps.c",
        "lib/readline/kill.c",
        "lib/readline/macro.c",
        "lib/readline/mbutil.c",
        "lib/readline/misc.c",
        "lib/readline/nls.c",
        "lib/readline/parens.c",
        "lib/readline/parse-colors.c",
        "lib/readline/readline.c",
        "lib/readline/rltty.c",
        "lib/readline/savestring.c",
        "lib/readline/search.c",
        "lib/readline/signals.c",
        "lib/readline/terminal.c",
        "lib/readline/text.c",
        "lib/readline/undo.c",
        "lib/readline/util.c",
        "lib/readline/vi_mode.c",
        "lib/readline/xfree.c",
        "lib/readline/xmalloc.c",
    ],
)

# .c files that other .c files #include textually rather than link separately.
# These go in a cc_library's `hdrs`, not `srcs`: anything in srcs gets compiled
# as its own translation unit, and these are not standalone-compilable (they
# reference macros like CHAR/FCT that only the includer defines).
filegroup(
    name = "readline_textual_includes",
    srcs = [
        # keymaps.c
        "lib/readline/emacs_keymap.c",
        "lib/readline/vi_keymap.c",
    ],
)

filegroup(
    name = "libsh_textual_includes",
    srcs = [
        # fmtullong.c / fmtumax.c. Also compiled on its own (see libsh_srcs):
        # being in srcs makes it a translation unit but does NOT make it
        # visible as an #include to siblings, so it must appear in both.
        "lib/sh/fmtulong.c",
        # strtoll.c / strtoull.c
        "lib/sh/strtol.c",
    ],
)

filegroup(
    name = "libglob_textual_includes",
    srcs = [
        # glob.c
        "lib/glob/glob_loop.c",
        # gmisc.c
        "lib/glob/gm_loop.c",
        # glob.c #includes gmisc.c, which is also its own translation unit.
        "lib/glob/gmisc.c",
        # smatch.c / strmatch.c
        "lib/glob/sm_loop.c",
    ],
)

# Scripts / data the deb ships verbatim.
exports_files([
    "support/bashbug.sh",
    "debian/clear_console.c",
    "debian/etc.bash.bashrc",
    "debian/skel.bashrc",
    "debian/skel.bash_logout",
    "debian/skel.profile",
    "debian/shells.d/bash",
    "debian/bash.menu",
])

# po/*.po -> the locale .mo files the deb installs under
# /usr/share/locale/<lang>/LC_MESSAGES/bash.mo. The 39 .po files match the 39
# .mo files in Make's deb exactly.
filegroup(
    name = "po_files",
    srcs = glob(
        ["po/*.po"],
        allow_empty = False,
    ),
)
