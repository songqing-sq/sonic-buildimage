#!/usr/bin/env python3
"""Hermetic launcher for DASH's SAI/sai_api_gen.py (Bazel stage 2).

The upstream sai_api_gen.py is heavily cwd-coupled: it os.chdir()s to its own
directory, imports the sibling ``utils`` package, reads ``templates/`` +
``specs/`` and the OCP SAI submodule at ``SAI/`` by relative path, and writes
generated headers/impls back in place. To keep the DASH source tree untouched
we stage a writable copy of the whole SAI/ dir (+ the OCP SAI submodule at
SAI/SAI) into a tmp dir and run the upstream script there via runpy, so its
os.chdir(__file__) lands in the writable stage and ``import utils`` resolves.

The third-party deps (jinja2 / pyyaml / pyyaml-include / jsonpath-ng) are
provided by this launcher's py_binary deps and are therefore importable in the
same interpreter that runpy re-enters.

argv: run_sai_gen.py <stage_dir> <p4rt_json> <ir_json>
"""
import os
import runpy
import sys


def main() -> None:
    stage_dir = os.path.realpath(sys.argv[1])
    p4rt_json = os.path.realpath(sys.argv[2])
    ir_json = os.path.realpath(sys.argv[3])

    script = os.path.join(stage_dir, "sai_api_gen.py")

    # Put the stage dir first on sys.path so the upstream `import utils` (and its
    # relative submodules) resolve against the staged copy.
    sys.path.insert(0, stage_dir)

    # Reproduce the exact CLI the DASH SAI/Makefile passes (target `all`):
    #   ./sai_api_gen.py <p4rt.json> --ir <ir.json> \
    #       --ignore-tables=underlay_mac,eni_meter,slb_decap \
    #       --sai-spec-dir=specs dash
    sys.argv = [
        script,
        p4rt_json,
        "--ir",
        ir_json,
        "--ignore-tables=underlay_mac,eni_meter,slb_decap",
        "--sai-spec-dir=specs",
        "dash",
    ]

    # sai_api_gen.py itself does os.chdir(dirname(realpath(__file__))); running
    # it via run_path makes __file__ == the staged script, so it chdirs into the
    # writable stage and reads/writes relative paths there.
    runpy.run_path(script, run_name="__main__")


if __name__ == "__main__":
    main()
