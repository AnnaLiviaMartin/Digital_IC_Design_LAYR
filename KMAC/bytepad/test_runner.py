# This file is public domain, it can be freely copied without restrictions.
# SPDX-License-Identifier: CC0-1.0

# test_runner.py

import os
from pathlib import Path

from cocotb_tools.runner import get_runner



def test_pad10_1_runner():
    sim = os.getenv("SIM", "icarus")
    
    proj_path = Path(__file__).resolve().parent
    
    sources = [ proj_path / "bytepad.sv"]

    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="bytepad"
    )

    runner.test(hdl_toplevel="bytepad", test_module="test_bytepad,")


if __name__ == "__main__":
    test_pad10_1_runner()
