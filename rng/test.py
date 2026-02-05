import os

from cocotb_tools.runner import get_runner

from pathlib import Path

def test_my_design_runner():
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent

    sources1 = [
        proj_path / "prng.sv"
    ]

    sources2 = [
        proj_path / "trng.sv"
    ]
    
    runner = get_runner(sim)
    runner.build(
        sources=sources1,
        hdl_toplevel="prng",
    )
    runner.test(hdl_toplevel="prng", test_module="prng_test")
    
    runner = get_runner(sim)
    runner.build(
        sources=sources2,
        hdl_toplevel="trng",
    )
    runner.test(hdl_toplevel="trng", test_module="trng_test")

if __name__ == "__main__":
    test_my_design_runner()
