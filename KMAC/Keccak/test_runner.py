import os
from pathlib import Path
from cocotb_tools.runner import get_runner

def test_my_design_runner():
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent  # Keccak-Ordner

    sources = [
        proj_path / "Keccak.sv",
        proj_path.parent / "pad10_1" / "pad10_1.sv"  # ../pad10_1/pad10_1.sv
    ]

    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="Keccak"
    )
    runner.test(hdl_toplevel="Keccak", test_module="test_keccak,")

if __name__ == "__main__":
    test_my_design_runner()
