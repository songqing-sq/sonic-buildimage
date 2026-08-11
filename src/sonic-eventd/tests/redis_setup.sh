# Module hook for the eventd suites (sourced by //cc:test_runner.sh).
#
# Starts a private redis and rewrites the fixture endpoints to match it. The
# runner supplies $SYSROOT / $WORKDIR / $libpath / $loader / run() and expects
# the hook to register its own EXIT trap and set SONIC_TEST_HAS_CLEANUP.
#
# Why the DB-backed cases need this at all: tests/main.cpp probes for a reachable
# redis in its global SetUp and records the result in g_is_redis_available; the
# cases check that flag and `return` early when it is false -- which gtest still
# reports as [ OK ]. So without a live server eventd.testDB silently never runs,
# and every eventdb_ut fixture GTEST_SKIPs.
#
# The tests reach the same instance two different ways: over TCP
# (DBConnector isTcpConn=true) and over the unix socket (stats_collector uses
# isTcpConn=false), so both endpoints have to be rewritten together.

# sockaddr_un.sun_path holds only 108 bytes and the sandboxed TEST_TMPDIR path
# alone is longer than that, so the socket needs a short home of its own.
sockdir=$(mktemp -d)
sock="$sockdir/r.sock"
mkdir -p "$WORKDIR/redis-data"

# Probing for a free port and then binding it is racy -- Bazel's sandbox does not
# isolate the network (this host has no unprivileged userns, so linux-sandbox -N
# is unavailable), and parallel eventd tests did collide. Let redis report the
# conflict and retry on another port. Seed from the pid, since two tests can
# start within the same wall-clock second.
port=$(awk -v s="$$" 'BEGIN{srand(s);print 20000+int(rand()*20000)}')
ready=0
attempt=0
while [ "$attempt" -lt 20 ]; do
    attempt=$((attempt + 1))
    # --save '' / --appendonly no keep it purely in-memory; there is nothing to
    # persist between runs.
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
    echo "eventd redis_setup.sh: redis-server did not come up; log follows" >&2
    cat "$WORKDIR/redis.log" >&2
    exit 1
fi
SONIC_TEST_HAS_CLEANUP=1

# Mirror the package dir into TEST_TMPDIR so the fixtures become writable:
# symlink every file, then replace the db config jsons with copies pointing at the
# endpoints redis actually bound. The runfiles tree is read-only, and this has to
# happen after the retry loop settles on a port.
pkgdir=$(dirname "$binary")
mirror="$WORKDIR/rundir"
mkdir -p "$mirror"
(cd "$pkgdir" && find . -type d) | while IFS= read -r d; do
    mkdir -p "$mirror/$d"
done
(cd "$pkgdir" && find . ! -type d) | while IFS= read -r f; do
    ln -sf "$pkgdir/${f#./}" "$mirror/$f"
done
for cfg in $(find "$pkgdir" -name '*.json' 2>/dev/null); do
    grep -q unix_socket_path "$cfg" || continue
    rel=${cfg#"$pkgdir"/}
    rm -f "$mirror/$rel"
    sed -e "s#\"unix_socket_path\"[[:space:]]*:[[:space:]]*\"[^\"]*\"#\"unix_socket_path\": \"$sock\"#g" \
        -e "s#\"port\"[[:space:]]*:[[:space:]]*[0-9]*#\"port\": $port#g" \
        "$cfg" > "$mirror/$rel"
done
cd "$mirror"
