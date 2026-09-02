#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

expect_fixed_action_environment() {
    grep -Fqx 'common --action_env=PATH=/usr/bin:/bin' "$ROOT/.bazelrc"
    grep -Fq 'export PATH="{}:/usr/bin:/bin"' "$ROOT/sonic_rules/kernel/host_tools.bzl"
    ! grep -Fq '${PATH' "$ROOT/sonic_rules/kernel/host_tools.bzl"
    grep -Fq 'use_default_shell_env = False' "$ROOT/sonic_rules/kernel/debian_kernel_config.bzl"
    grep -Fq 'use_default_shell_env = False' "$ROOT/sonic_rules/kernel/kernel_build.bzl"
}

expect_declared_kernel_resources() {
    grep -Fq 'jobs = ctx.attr.jobs' "$ROOT/sonic_rules/kernel/kernel_build.bzl"
    grep -Fq 'resource_set = _KERNEL_RESOURCE_SETS[jobs]' "$ROOT/sonic_rules/kernel/kernel_build.bzl"
    grep -Fq '"jobs": attr.int(default = 48, values = [24, 48, 72, 96])' "$ROOT/sonic_rules/kernel/kernel_build.bzl"
    grep -Fq -- '-j{jobs}' "$ROOT/sonic_rules/kernel/kernel_build.bzl"
    ! grep -Fq 'NPROC="$(nproc)"' "$ROOT/sonic_rules/kernel/kernel_build.bzl"
}

expect_multiarch_kernel_entrypoint() {
    grep -Fq 'load("@sonic_build_infra//kernel:defs.bzl", "sonic_kernel")' "$ROOT/src/sonic-linux-kernel/BUILD.bazel"
    grep -Fq 'sonic_kernel(' "$ROOT/src/sonic-linux-kernel/BUILD.bazel"
    grep -Fq '"amd64": {' "$ROOT/src/sonic-linux-kernel/BUILD.bazel"
    grep -Fq '"arm64": {' "$ROOT/src/sonic-linux-kernel/BUILD.bazel"
    grep -Fq '"news_file_suffix": "/debian/linux-image-6.12.41+deb13-amd64-unsigned.NEWS"' "$ROOT/src/sonic-linux-kernel/BUILD.bazel"
    grep -Fq '"news_file_suffix": "/debian/linux-image-6.12.41+deb13-arm64-unsigned.NEWS"' "$ROOT/src/sonic-linux-kernel/BUILD.bazel"
    grep -Fq 'linux_kbuild_package = "linux-kbuild-6.12+deb13"' "$ROOT/src/sonic-linux-kernel/BUILD.bazel"
    grep -Fq 'linux_kbuild_package,' "$ROOT/sonic_rules/kernel/defs.bzl"
    ! grep -Fq '"linux-kbuild-6.1 (>= "' "$ROOT/sonic_rules/kernel/defs.bzl"
}

expect_fixed_action_environment
expect_declared_kernel_resources
expect_multiarch_kernel_entrypoint
