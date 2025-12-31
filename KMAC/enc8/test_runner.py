# This file is public domain, it can be freely copied without restrictions.
# SPDX-License-Identifier: CC0-1.0
# test_runner.py

import os
from pathlib import Path
from cocotb_tools.runner import get_runner


def test_my_design_runner():
    sim = os.getenv("SIM", "icarus")

    proj_path = Path(__file__).resolve().parent

    sources = [proj_path / "enc8.sv"]

    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="enc8_kmac"
    )

    runner.test(hdl_toplevel="enc8_kmac", test_module="test_enc8,")


if __name__ == "__main__":
    test_my_design_runner()