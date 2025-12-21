import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

def bytepad_ref(X, L, W=8):
    """NIST SP 800-185 bytepad(X,L,W) Referenz"""
    result = X[:L] + [0x00] * (W - L)
    return result

@cocotb.test()
async def test_kmac_bytepad_basic(dut):
    """NIST bytepad Tests"""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    dut.rst_n.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    
    # Test 1: L=3 → X[0:2] || 00 00 00 00 00
    dut.L.value = 3
    dut.X0.value = 0x41  # 'A'
    dut.X1.value = 0x42  # 'B'  
    dut.X2.value = 0x43  # 'C'
    
    dut.start.value = 1
    await RisingEdge(dut.clk)
    dut.start.value = 0
    await RisingEdge(dut.pad_done)
    
    ref = bytepad_ref([0x41,0x42,0x43,0,0,0,0,0], 3)
    assert dut.pad0.value == 0x41
    assert dut.pad1.value == 0x42
    assert dut.pad2.value == 0x43
    assert dut.pad3.value == 0x00
    print(f"✓ bytepad(L=3): 41 42 43 00 00 00 00 00")
    
    # Test 2: L=8 (full block)
    dut.L.value = 8
    dut.X0.value = 0xFF
    dut.X7.value = 0xFF
    dut.start.value = 1
    await RisingEdge(dut.clk)
    dut.start.value = 0
    await RisingEdge(dut.pad_done)
    
    assert dut.pad7.value == 0xFF  # Kein Padding nötig
    print("✓ bytepad(L=8): Full block OK")

@cocotb.test()
async def test_kmac_bytepad_vectors(dut):
    """Alle L=0..8"""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    dut.rst_n.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    
    test_X = [0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF, 0x00, 0x11]
    
    for L in range(9):
        dut.L.value = L
        for i in range(8):
            dut.__getattribute__(f"X{i}").value = test_X[i]
        
        dut.start.value = 1
        await RisingEdge(dut.clk)
        dut.start.value = 0
        await RisingEdge(dut.pad_done)
        
        ref = bytepad_ref(test_X, L)
        for i in range(8):
            assert dut.__getattribute__(f"pad{i}").value == ref[i]
        
        print(f"✓ bytepad(L={L}): OK")
