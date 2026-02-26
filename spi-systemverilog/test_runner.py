# test_runner.py
import os
from pathlib import Path
from cocotb_tools.runner import get_runner

def test_spi_runner():
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent
    
    sources = [
        proj_path / "spi.sv",      
        proj_path / "spi_top.sv"   
    ]

    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="top"
    )

    runner.test(hdl_toplevel="top", test_module="test_spi")  # test_spi.py

if __name__ == "__main__":
    test_spi_runner()
