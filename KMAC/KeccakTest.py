import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer, First

@cocotb.test()
async def test_keccak_basic(dut):
    """Grundtest: Keccak(c=576, X=3) → L = x || 10^z"""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    # Reset
    dut.rst_n.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    
    # Standard Keccak-f1600: c=576 → r=1600-576=1024
    dut.c.value = 576
    dut.X.value = 3
    dut.start.value = 0
    
    # Start pulse
    dut.start.value = 1
    await RisingEdge(dut.clk)
    dut.start.value = 0
    
    # Auf done warten
    await First(RisingEdge(dut.done), Timer(200_000, units="ns"))
    
    assert dut.done.value == 1, "Timeout: Keccak done nicht gesetzt"
    print(f"Keccak(c=576, X=3): L={dut.L.value.integer:032x}, z={dut.pad_inst.z_out.value}")
