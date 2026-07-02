load("@aspect_rules_py//py:defs.bzl", "py_library")
load("@bazel_skylib//rules:write_file.bzl", "write_file")
load("@rules_python//python:packaging.bzl", "py_wheel")
load("@tar.bzl", "tar")

package(default_visibility = ["//visibility:public"])

VERSION = "2.6.1.dev0"

# =============================================================================
# scapy BUILD template — instantiated by sonic_http_archive at fetch time.
#
# By the time this file executes, sonic_http_archive has already:
#   1. Downloaded the upstream tarball github.com/secdev/scapy@<COMMIT>.tar.gz
#   2. Applied SONiC patches (from src/scapy-py3/patch/series):
#        - 0001-Fix-version-string-generation-when-scapy-is-a-submod.patch
#        - 0004-Fix-fd-leak-in-worker-thread.patch
#
# strip_prefix was `scapy-<commit>/`, so the current package root already
# contains `setup.py`, `pyproject.toml`, `scapy/`, `doc/`, etc.
#
# Wheel name mirrors rules/scapy.mk: scapy-2.6.1.dev0-py3-none-any.whl. The
# dist version (VERSION) is decoupled from the source commit — SONiC ships
# a "dev" tag so local builds don't clash with upstream releases.
# =============================================================================

# Generate the scapy/VERSION file that setup.py's BuildPy._build_version
# hook would normally write at build time. py_wheel does not run setuptools
# cmdclass hooks, so we materialize the same content here.
write_file(
    name = "scapy_version_file",
    out = "scapy/VERSION",
    content = [VERSION],
    newline = "unix",
)

# Sources — every upstream python file (patched during http_archive fetch).
py_library(
    name = "sources",
    srcs = glob(
        include = ["scapy/**/*.py"],
        allow_empty = False,
    ) + [":scapy_version_file"],
    data = glob(
        include = ["scapy/py.typed"],
        allow_empty = True,
    ),
    imports = ["."],
    visibility = ["//visibility:public"],
)

# Wheel artifact (mirrors rules/scapy.mk: scapy-2.6.1.dev0-py3-none-any.whl).
py_wheel(
    name = "wheel",
    distribution = "scapy",
    version = VERSION,
    author = "Philippe BIONDI",
    author_email = "phil@secdev.org",
    homepage = "https://scapy.net",
    project_urls = {
        "Homepage": "https://scapy.net",
        "Download": "https://github.com/secdev/scapy/tarball/master",
        "Documentation": "https://scapy.readthedocs.io",
        "Source Code": "https://github.com/secdev/scapy",
        "Changelog": "https://github.com/secdev/scapy/releases",
    },
    summary = "Scapy: interactive packet manipulation tool",
    license = "GPL-2.0-only",
    python_requires = ">=3.7, <4",
    classifiers = [
        "Development Status :: 5 - Production/Stable",
        "Environment :: Console",
        "Intended Audience :: Developers",
        "Intended Audience :: Information Technology",
        "Intended Audience :: Science/Research",
        "Intended Audience :: System Administrators",
        "Intended Audience :: Telecommunications Industry",
        "License :: OSI Approved :: GNU General Public License v2 (GPLv2)",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3 :: Only",
        "Programming Language :: Python :: 3.7",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
        "Programming Language :: Python :: 3.12",
        "Programming Language :: Python :: 3.13",
        "Topic :: Security",
        "Topic :: System :: Networking",
        "Topic :: System :: Networking :: Monitoring",
    ],
    extra_requires = {
        "cli": ["ipython"],
        "all": ["ipython", "pyx", "cryptography>=2.0", "matplotlib"],
        "doc": ["sphinx>=7.0.0", "sphinx_rtd_theme>=1.3.0", "tox>=3.0.0"],
    },
    entry_points = {
        "console_scripts": [
            "scapy = scapy.main:interact",
        ],
    },
    # setup.py: data_files=[('share/man/man1', ['doc/scapy.1'])]
    data_files = {
        "doc/scapy.1": "data/share/man/man1/scapy.1",
    },
    extra_distinfo_files = {
        "LICENSE": "LICENSE",
    },
    deps = [":sources"],
    python_tag = "py3",
    visibility = ["//visibility:public"],
)

# Console script that pip generates at install time.
write_file(
    name = "scapy_console_script",
    out = "scapy_script",
    content = [
        "#!/usr/bin/python3",
        "# -*- coding: utf-8 -*-",
        "import re",
        "import sys",
        "from scapy.main import interact",
        "if __name__ == '__main__':",
        "    sys.argv[0] = re.sub(r'(-script\\.pyw|\\.exe)?$', '', sys.argv[0])",
        "    sys.exit(interact())",
    ],
)

# Install tar layer — OCI-image consumers use this instead of the wheel.
tar(
    name = "install",
    srcs = [":scapy_console_script"],
    mtree = [
        "./usr/local/bin/scapy uid=0 gid=0 mode=0755 type=file content=$(location :scapy_console_script)",
    ],
    visibility = ["//visibility:public"],
)
