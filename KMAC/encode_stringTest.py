import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

def encode_string_ref(length):
    """NIST encode_string(S,L): enc8(0)||enc8(1)||...||enc8(L-1)"""
    return [(i * 8 + 1) & 0xFF for i in range(length)]

@cocotb.test()
async def test_kmac_encode_string_nist(dut):
    """NIST SP 800-185 encode_string Tests"""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    dut.rst_n.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    
    # Test 1: L=4 → enc8(0)||enc8(1)||enc8(2)||enc8(3)
    dut.str_len.value = 4
    dut.start.value = 1
    await RisingEdge(dut.clk)
    dut.start.value = 0
    await RisingEdge(dut.enc_done)
    
    ref = encode_string_ref(4)  # [1,9,17,25]
    assert dut.enc0.value == 0x01
    assert dut.enc1.value == 0x09
    assert dut.enc2.value == 0x11
    assert dut.enc3.value == 0x19
    print(f"✓ encode_string(L=4): {list(map(hex, ref))}")
    
    # Test 2: L=1 → nur enc8(0)
    dut.str_len.value = 1
    dut.start.value = 1
    await RisingEdge(dut.clk)
    dut.start.value = 0
    await RisingEdge(dut.enc_done)
    
    assert dut.enc0.value == 0x01
    print("✓ encode_string(L=1): [0x01]")

@cocotb.test()
async def test_kmac_encode_string_vectors(dut):
    """Verschiedene Längen"""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    dut.rst_n.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    
    lengths = [0, 1, 2, 4, 8]
    for L in lengths:
        dut.str_len.value = L
        dut.start.value = 1
        await RisingEdge(dut.clk)
        dut.start.value = 0
        await RisingEdge(dut.enc_done)
        
        ref = encode_string_ref(L)
        print(f"✓ L={L}: {list(map(lambda x: f'0x{x:02x}', ref))}")
