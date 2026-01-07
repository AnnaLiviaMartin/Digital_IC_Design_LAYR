import os
from pathlib import Path
from cocotb_tools.runner import get_runner

def test_my_design_runner():
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent  # Keccak-Ordner

    sources = [
        proj_path / "KMACStatemachine.sv",
        proj_path.parent / "pad10_1" / "pad10_1.sv",
        proj_path.parent / "right_encode" / "right_encode.sv",
        proj_path.parent / "encode_string" / "encode_string.sv",
        proj_path.parent / "bytepad" / "bytepad.sv",
        proj_path.parent / "enc8" / "enc8.sv",
        proj_path.parent / "Keccak" / "Keccak.sv"
    ]

    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="kmac_top_cshake"
    )
    runner.test(hdl_toplevel="kmac_top_cshake", test_module="test_KMACStatemachine,")

if __name__ == "__main__":
    test_my_design_runner()
