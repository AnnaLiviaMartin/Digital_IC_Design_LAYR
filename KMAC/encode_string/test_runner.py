import os
from pathlib import Path
from cocotb_tools.runner import get_runner

def test_my_design_runner():
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent  # encode_string Ordner

    sources = [
        proj_path / "encode_string.sv",
        proj_path.parent / "enc8" / "enc8.sv"  # ../enc8/enc8_kmac.sv
    ]

    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="kmac_encode_string"  # Dein Top-Level-Modul
    )
    runner.test(hdl_toplevel="kmac_encode_string", test_module="test_encode_string")

if __name__ == "__main__":
    test_my_design_runner()
