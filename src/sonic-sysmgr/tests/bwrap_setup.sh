# Module hook for sysmgr_ut (sourced by //cc:test_runner.sh).
#
# The RebootBE / RebootThread fixtures construct swss::DBConnector directly, and
# SonicDBConfig then falls back to its hardcoded absolute
# DEFAULT_SONIC_DB_CONFIG_FILE (/var/run/redis/sonic-db/database_config.json).
# That path is not writable in the sandbox and swsscommon exposes no env-var
# override, so the config is staged and bind-mounted into place with bubblewrap.
# /var/run is a symlink to /run, so the bind target is /run/redis.
#
# The bind list is deliberately narrow. An earlier version used
# `--dev-bind / /`, which handed the test process the entire host filesystem --
# the opposite of what the rest of this runner works to achieve. Only the
# directories the binary genuinely needs are exposed, all read-only except the
# staged config.

dbcfg=$(find "$RUNFILES" -maxdepth 3 -name 'database_config.json' 2>/dev/null | head -1)
bwrap=$(find "$SYSROOT" -name 'bwrap' -type f 2>/dev/null | head -1)

if [ -z "$dbcfg" ] || [ -z "$bwrap" ]; then
    echo "sysmgr bwrap_setup.sh: need both database_config.json and bwrap in runfiles" >&2
    exit 1
fi

mkdir -p "$WORKDIR/sonic-db"
cp "$dbcfg" "$WORKDIR/sonic-db/database_config.json"

# bwrap is itself a staged trixie binary, so it needs the staged libs -- but
# LD_LIBRARY_PATH must not be inherited by what it spawns, or every child hits
# the loader/libc mismatch. Drive bwrap through the loader's --library-path
# (which does not propagate) and let the launch prefix set LD_LIBRARY_PATH for
# the test binary alone.
_bwrap_libs=$(find "$SYSROOT" \( -name 'libcap.so.*' -o -name 'libselinux.so.*' \) 2>/dev/null |
    while IFS= read -r so; do dirname "$so"; done | sort -u | tr '\n' ':')

# Everything the test reads lives under the bazel output tree, the runfiles, or
# TEST_TMPDIR; expose those read-only, plus /proc and /dev for the runtime.
SONIC_TEST_LAUNCH_PREFIX="$loader --library-path ${_bwrap_libs}${libpath} $bwrap \
    --ro-bind $RUNFILES $RUNFILES \
    --bind $WORKDIR $WORKDIR \
    --proc /proc \
    --dev /dev \
    --tmpfs /run \
    --bind $WORKDIR/sonic-db /run/redis/sonic-db \
    -- env LD_LIBRARY_PATH=$libpath $loader"
