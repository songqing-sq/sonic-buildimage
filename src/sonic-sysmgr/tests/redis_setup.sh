# Module hook for sysmgr_ut (sourced by //cc:test_runner.sh).
#
# The RebootBE / RebootThread fixtures hold swss::DBConnector members
# (STATE_DB, CONFIG_DB) plus NotificationProducer / NotificationConsumer, so they
# need a live redis -- not just a parseable config. SonicDBConfig also falls back
# to its hardcoded absolute DEFAULT_SONIC_DB_CONFIG_FILE
# (/var/run/redis/sonic-db/database_config.json) when nothing has initialised it,
# and swsscommon exposes no env-var override.
#
# So: start a private redis, emit a config that points at it, and hand that path to
# the suite through SONIC_DB_CONFIG_FILE -- the Bazel-only test main initialises
# SonicDBConfig from it. No bind mount and no bubblewrap, which is what previously
# made this target unrunnable on hosts that forbid userns nesting.

# sockaddr_un.sun_path holds only 108 bytes and the sandboxed TEST_TMPDIR path
# alone is longer, so the socket needs a short home of its own.
sockdir=$(mktemp -d)
sock="$sockdir/r.sock"
mkdir -p "$WORKDIR/redis-data" "$WORKDIR/sonic-db"

# Probing for a free port then binding it is racy -- Bazel's sandbox does not
# isolate the network -- so let redis report the conflict and retry. Seed from the
# pid, since two tests can start in the same wall-clock second.
port=$(awk -v s="$$" 'BEGIN{srand(s);print 20000+int(rand()*20000)}')
ready=0
attempt=0
while [ "$attempt" -lt 20 ]; do
    attempt=$((attempt + 1))
    run "$SYSROOT/usr/bin/redis-server" \
        --port "$port" \
        --unixsocket "$sock" \
        --bind 127.0.0.1 \
        --save '' \
        --appendonly no \
        --dir "$WORKDIR/redis-data" >"$WORKDIR/redis.log" 2>&1 &
    redis_pid=$!
    trap 'kill "$redis_pid" 2>/dev/null || true; rm -rf "$sockdir"' EXIT INT TERM

    for _ in $(seq 1 80); do
        if run "$SYSROOT/usr/bin/redis-cli" -s "$sock" ping 2>/dev/null | grep -q PONG; then
            ready=1
            break
        fi
        kill -0 "$redis_pid" 2>/dev/null || break
        sleep 0.25
    done
    [ "$ready" = 1 ] && break

    kill "$redis_pid" 2>/dev/null || true
    grep -q 'Address already in use' "$WORKDIR/redis.log" || break
    port=$((port + 1))
done
if [ "$ready" != 1 ]; then
    echo "sysmgr redis_setup.sh: redis-server did not come up; log follows" >&2
    cat "$WORKDIR/redis.log" >&2
    exit 1
fi
SONIC_TEST_HAS_CLEANUP=1

# swsscommon's own database_config.json travels with its runfiles; rewrite its
# endpoints to the instance just started rather than hardcoding a repo name.
dbcfg=$(find "$RUNFILES" -maxdepth 3 -name 'database_config.json' 2>/dev/null | head -1)
if [ -z "$dbcfg" ]; then
    echo "sysmgr redis_setup.sh: no database_config.json in runfiles" >&2
    exit 1
fi
sed -e "s#\"unix_socket_path\"[[:space:]]*:[[:space:]]*\"[^\"]*\"#\"unix_socket_path\": \"$sock\"#g" \
    -e "s#\"port\"[[:space:]]*:[[:space:]]*[0-9]*#\"port\": $port#g" \
    "$dbcfg" > "$WORKDIR/sonic-db/database_config.json"

# No bwrap, no bind mount: the Bazel-only test main (see :gen_test_main) calls
# SonicDBConfig::initialize(getenv("SONIC_DB_CONFIG_FILE")), so the rewritten
# config is picked up from wherever it happens to live. That sidesteps the
# hardcoded /var/run/redis path entirely -- and with it the userns nesting this
# build host does not allow.
SONIC_TEST_LAUNCH_PREFIX="env SONIC_DB_CONFIG_FILE=$WORKDIR/sonic-db/database_config.json LD_LIBRARY_PATH=$libpath $loader"
