load("@aspect_rules_py//py:defs.bzl", "py_library")
load("@bazel_skylib//rules:write_file.bzl", "write_file")
load("@rules_python//python:packaging.bzl", "py_wheel")
load("@tar.bzl//:tar.bzl", "tar")

package(default_visibility = ["//visibility:public"])

VERSION = "1.1"

# redisdl.py is already patched at fetch time via sonic_http_archive(patches=).
py_library(
    name = "sources",
    srcs = ["redisdl.py"],
    imports = ["."],
)

write_file(
    name = "top_level_txt",
    out = "top_level.txt",
    content = ["redisdl"],
)

py_wheel(
    name = "wheel",
    distribution = "redis-dump-load",
    version = VERSION,
    author = "Oleg Pudeyev",
    author_email = "oleg@bsdpower.com",
    summary = "Dump and load redis databases",
    homepage = "http://github.com/p/redis-dump-load",
    license = "BSD",
    classifiers = [
        "Development Status :: 4 - Beta",
        "Environment :: Console",
        "Intended Audience :: Developers",
        "Intended Audience :: System Administrators",
        "License :: OSI Approved :: BSD License",
        "Operating System :: OS Independent",
        "Programming Language :: Python :: 2",
        "Programming Language :: Python :: 3",
        "Topic :: Database",
        "Topic :: System :: Archiving",
    ],
    requires = ["redis"],
    entry_points = {
        "console_scripts": [
            "redis-load = redisdl:main",
            "redis-dump = redisdl:main",
        ],
    },
    data_files = {
        "LICENSE": "data/share/doc/redis-dump-load/LICENSE",
        "README.rst": "data/share/doc/redis-dump-load/README.rst",
    },
    extra_distinfo_files = {
        "LICENSE": "LICENSE",
        ":top_level_txt": "top_level.txt",
    },
    deps = [":sources"],
)

write_file(
    name = "redis_load_script",
    out = "redis-load",
    content = [
        "#!/usr/bin/python3",
        "# -*- coding: utf-8 -*-",
        "import re",
        "import sys",
        "from redisdl import main",
        "if __name__ == '__main__':",
        "    sys.argv[0] = re.sub(r'(-script\\.pyw|\\.exe)?$', '', sys.argv[0])",
        "    sys.exit(main())",
    ],
)

write_file(
    name = "redis_dump_script",
    out = "redis-dump",
    content = [
        "#!/usr/bin/python3",
        "# -*- coding: utf-8 -*-",
        "import re",
        "import sys",
        "from redisdl import main",
        "if __name__ == '__main__':",
        "    sys.argv[0] = re.sub(r'(-script\\.pyw|\\.exe)?$', '', sys.argv[0])",
        "    sys.exit(main())",
    ],
)

tar(
    name = "install",
    srcs = [
        "redisdl.py",
        "LICENSE",
        "README.rst",
        ":redis_load_script",
        ":redis_dump_script",
    ],
    mtree = [
        "./usr/lib/python3/dist-packages/redisdl.py uid=0 gid=0 mode=0644 type=file content=$(location redisdl.py)",
        "./usr/local/share/doc/redis-dump-load/LICENSE uid=0 gid=0 mode=0644 type=file content=$(location LICENSE)",
        "./usr/local/share/doc/redis-dump-load/README.rst uid=0 gid=0 mode=0644 type=file content=$(location README.rst)",
        "./usr/local/bin/redis-load uid=0 gid=0 mode=0755 type=file content=$(location :redis_load_script)",
        "./usr/local/bin/redis-dump uid=0 gid=0 mode=0755 type=file content=$(location :redis_dump_script)",
    ],
)
