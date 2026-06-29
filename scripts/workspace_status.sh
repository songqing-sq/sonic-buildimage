#!/bin/bash
# CI/release sets RELEASE_BUILD=1 for accurate timestamps in every build.
# Dev builds default to VOLATILE_ so timestamps don't break caching.
if [ "${RELEASE_BUILD:-}" = "1" ]; then
  PREFIX="STABLE"
else
  PREFIX="VOLATILE"
fi

echo "STABLE_COMMIT_ID $(git rev-parse --short HEAD 2>/dev/null || echo unknown)"
echo "STABLE_BRANCH $(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)"
echo "${PREFIX}_BUILD_DATE $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "${PREFIX}_BUILT_BY ${USER:-bazel}"
echo "${PREFIX}_BUILD_NUMBER ${BUILD_NUMBER:-0}"
