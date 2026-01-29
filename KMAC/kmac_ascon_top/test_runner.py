import os
from pathlib import Path
from cocotb_tools.runner import get_runner

def test_kmac_ascon_top_runner():
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent  # kmac_ascon_top/
    
    sources = [
        proj_path / "kmac_ascon_top.sv",
        proj_path.parent / "KMACStatemachine" / "KMACStatemachine.sv",  # kmac_top_cshake
        proj_path.parent / "ascon" / "ascon_state_machine_top.sv",     # ✅ ECHTES Modul!
        proj_path.parent / "pad10_1" / "pad10_1.sv",
        proj_path.parent / "right_encode" / "right_encode.sv",
        proj_path.parent / "encode_string" / "encode_string.sv",
        proj_path.parent / "bytepad" / "bytepad.sv",
        proj_path.parent / "enc8" / "enc8.sv",
        proj_path.parent / "Keccak" / "Keccak.sv",
        proj_path.parent / "ascon" / "ascon_state_machine.sv",         # Zusätzlich
        proj_path.parent / "ascon" / "ascon_permutation.sv"           # Falls nötig
    ]
    
    runner = get_runner(sim)
    runner.build(sources=sources, hdl_toplevel="kmac_ascon_top")
    runner.test(hdl_toplevel="kmac_ascon_top", test_module="test_kmac_ascon_top")

if __name__ == "__main__":
    test_kmac_ascon_top_runner()
