import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer, First

def bytepad_ref(X, L, W=8):
    """NIST SP 800-185 bytepad(X,L,W) Referenz"""
    result = X[:L] + [0x00] * (W - L)
    return result

@cocotb.test()
async def test_kmac_bytepad_basic(dut):
    """NIST bytepad Tests"""
    clock = Clock(dut.clk, 10, unit="ns")
    cocotb.start_soon(clock.start())
    
    # Reset
    dut.rst_n.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    
    # Test 1: L=3 (BEKANNT FUNKTIONIERT!)
    dut.L.value = 3
    dut.X_bytes[0].value = 0x41
    dut.X_bytes[1].value = 0x42
    dut.X_bytes[2].value = 0x43
    
    # Start pulse: 1 Clock high, dann low
    dut.start.value = 1
    await RisingEdge(dut.clk)
    dut.start.value = 0
    
    # Warte auf pad_done (mit Timeout)
    timeout = Timer(50_000, unit="ns")
    await First(RisingEdge(dut.pad_done), timeout)
    assert dut.pad_done.value == 1, "pad_done timeout L=3!"
    
    assert dut.pad_bytes[0].value.to_unsigned() == 0x41
    assert dut.pad_bytes[1].value.to_unsigned() == 0x42
    assert dut.pad_bytes[2].value.to_unsigned() == 0x43
    assert dut.pad_bytes[3].value.to_unsigned() == 0x00
    print(f"✓ bytepad(L=3): 41 42 43 00 00 00 00 00")
    
    # Reset für Test 2
    dut.rst_n.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    
    # Test 2: L=7
    dut.L.value = 7
    for i in range(8):
        dut.X_bytes[i].value = 0xFF
    
    dut.start.value = 1
    await RisingEdge(dut.clk)
    dut.start.value = 0
    
    timeout = Timer(50_000, unit="ns")
    await First(RisingEdge(dut.pad_done), timeout)
    assert dut.pad_done.value == 1, "pad_done timeout L=7!"
    
    assert dut.pad_bytes[6].value.to_unsigned() == 0xFF
    assert dut.pad_bytes[7].value.to_unsigned() == 0x00
    print("✓ bytepad(L=7): FFFFFFFF 00")

@cocotb.test()
async def test_kmac_bytepad_vectors(dut):
    """Alle L=0..7"""
    clock = Clock(dut.clk, 10, unit="ns")
    cocotb.start_soon(clock.start())
    
    dut.rst_n.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    
    test_X = [0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF, 0x00, 0x11]
    
    for L in range(8):
        # Reset vor jedem Test!
        dut.rst_n.value = 0
        await RisingEdge(dut.clk)
        dut.rst_n.value = 1
        
        dut.L.value = L
        for i in range(8):
            dut.X_bytes[i].value = test_X[i]
        
        dut.start.value = 1
        await RisingEdge(dut.clk)
        dut.start.value = 0
        
        timeout = Timer(50_000, unit="ns")
        await First(RisingEdge(dut.pad_done), timeout)
        assert dut.pad_done.value == 1, f"pad_done timeout L={L}!"
        
        ref = bytepad_ref(test_X, L)
        for i in range(8):
            assert dut.pad_bytes[i].value.to_unsigned() == ref[i]
        
        print(f"✓ bytepad(L={L}): OK")
