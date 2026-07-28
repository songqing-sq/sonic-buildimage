#!/usr/bin/env python3
"""Pack the sonic-device-data payload, driving the repo's own VS generator.

The legacy Makefile does three things:
  1. writes `vs` into device/virtual/x86_64-kvm_x86_64-r0/platform_asic
  2. flattens device/<vendor>/<platform>/... into ./device/<platform>/...
     (`cp -r -L`, so symlinks are dereferenced)
  3. runs src/generate_vs_hwsku.py to synthesize the VS hwskus

Step 3 is the repo's own script and is invoked here rather than reimplemented,
so the VS hwsku layout stays whatever that script produces. This wrapper only
does the staging around it and the final tar.
"""

import argparse
import os
import shutil
import subprocess
import sys
import tarfile

TAR_PREFIX = "./usr/share/sonic/device"


def flatten_vendor_tree(device_root, staging_device_dir):
    """device/<vendor>/<platform> -> <staging>/<platform>, dereferencing links.

    Mirrors `cp -r -L ../../../device/*/* ./device/`: the shell glob skips
    dotfiles at both levels.
    """
    for vendor in sorted(os.listdir(device_root)):
        if vendor.startswith("."):
            continue
        vendor_path = os.path.join(device_root, vendor)
        if not os.path.isdir(vendor_path):
            continue
        for entry in sorted(os.listdir(vendor_path)):
            if entry.startswith("."):
                continue
            src = os.path.join(vendor_path, entry)
            dst = os.path.join(staging_device_dir, entry)
            if os.path.isdir(src):
                shutil.copytree(src, dst, symlinks=False, dirs_exist_ok=True)
            else:
                shutil.copy2(src, dst)


def write_platform_asic(device_root):
    """`echo vs > device/virtual/x86_64-kvm_x86_64-r0/platform_asic`.

    Written into the SOURCE tree copy before flattening, which is why the
    packaged path ends up as device/virtual/... rather than under the flattened
    platform dir.
    """
    target = os.path.join(device_root, "virtual", "x86_64-kvm_x86_64-r0")
    if not os.path.isdir(target):
        return
    with open(os.path.join(target, "platform_asic"), "w") as f:
        f.write("vs\n")


def add_to_tar(tar, staging_device_dir):
    def reset(ti):
        ti.uid = 0
        ti.gid = 0
        ti.uname = "root"
        ti.gname = "root"
        ti.mtime = 0
        if ti.isdir():
            ti.mode = 0o755
        elif ti.mode & 0o111:
            ti.mode = 0o755
        else:
            ti.mode = 0o644
        return ti

    for name in sorted(os.listdir(staging_device_dir)):
        tar.add(
            os.path.join(staging_device_dir, name),
            arcname="%s/%s" % (TAR_PREFIX, name),
            filter=reset,
        )


def main(argv):
    ap = argparse.ArgumentParser()
    ap.add_argument("--device-root", required=True)
    ap.add_argument("--vs-profiles-dir", required=True)
    ap.add_argument("--generator", required=True)
    ap.add_argument("--out", required=True)
    args = ap.parse_args(argv[1:])

    out = os.path.abspath(args.out)
    work = os.path.abspath("_device_data_stage")
    os.makedirs(work, exist_ok=True)

    # The generator writes into <its own dir>/device/, and reads the VS profile
    # files from that same dir, so stage a writable copy of both.
    gen_dir = os.path.join(work, "gen")
    os.makedirs(gen_dir, exist_ok=True)
    for name in os.listdir(args.vs_profiles_dir):
        src = os.path.join(args.vs_profiles_dir, name)
        if os.path.isfile(src):
            shutil.copy2(src, os.path.join(gen_dir, name))

    # Writable copy of the source device tree (platform_asic is written into it).
    device_src = os.path.join(work, "device_src")
    shutil.copytree(args.device_root, device_src, symlinks=True, dirs_exist_ok=True)
    write_platform_asic(device_src)

    staging_device_dir = os.path.join(gen_dir, "device")
    os.makedirs(staging_device_dir, exist_ok=True)
    flatten_vendor_tree(device_src, staging_device_dir)

    # generate_vs_hwsku.py derives its src_dir from __file__ (that is where it
    # reads the VS profiles and writes device/), so run it FROM the staged dir.
    generator = os.path.join(gen_dir, "generate_vs_hwsku.py")
    shutil.copy2(args.generator, generator)
    subprocess.run(
        [sys.executable, generator, device_src],
        cwd=gen_dir,
        check=True,
    )

    with tarfile.open(out, "w:gz") as tar:
        add_to_tar(tar, staging_device_dir)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
