import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

@cocotb.test()
async def test_keccak_basic(dut):
    clock = Clock(dut.clk, 10, unit="ns")
    cocotb.start_soon(clock.start())
    
    # Reset
    dut.rst_n.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    
    # DEBUG Hierarchie
    print("=== Keccak HIERARCHIE ===")
    for attr in dir(dut):
        if not attr.startswith('_'):
            try:
                print(f"  {attr} = {getattr(dut, attr).value}")
            except:
                pass
    print("=== ENDE ===")
    
    # Test start -> done (PYTHON Zahlen!)
    dut.c.value = 42      # ← 8'd256 → 256
    dut.X.value = 42       # ← 8'd42  → 42
    
    dut.start.value = 1
    await RisingEdge(dut.clk)
    dut.start.value = 0
    
    # Warte auf done (max 1000 Zyklen)
    timeout = 1000
    while int(dut.done.value) == 0 and timeout > 0:
        await RisingEdge(dut.clk)
        timeout -= 1
    
    assert dut.done.value == 1, "Timeout: done nicht gesetzt!"
    print(f"✓ done = {dut.done.value}")
    print(f"✓ L = {int(dut.L.value)}")
