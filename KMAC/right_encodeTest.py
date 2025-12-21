import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
from cocotb.result import TestFailure
import pytest

def verify_kmac_right_pad(bit_len, enc8_vals, pad_out):
    """Referenz-Check NIST KMAC right-pad"""
    # 1. Bit[bit_len] muss 1 sein
    if bit_len < 64:
        assert pad_out.value.integer & (1 << bit_len), \
            f"Bit[{bit_len}] != 1"
    
    # 2. Bits[0:bit_len] müssen 0 sein  
    mask = (1 << (bit_len + 1)) - 1
    assert (pad_out.value.integer & mask) == (1 << bit_len), \
        f"Bits[0:{bit_len}] != 0^(bit_len+1)"
    
    # 3. enc8-Bytes an korrekten Positionen
    assert pad_out.value[39:32].integer == enc8_vals[0], "enc8_0 falsch"
    assert pad_out.value[47:40].integer == enc8_vals[1], "enc8_1 falsch"
    assert pad_out.value[55:48].integer == enc8_vals[2], "enc8_2 falsch"
    assert pad_out.value[63:56].integer == enc8_vals[3], "enc8_3 falsch"

@cocotb.test()
async def test_kmac_right_pad_basic(dut):
    """NIST KMAC right-pad: bit_len=8"""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    dut.rst_n.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    
    # enc8(0..3): 1,9,17,25
    dut.bit_len.value = 8
    dut.enc8_0.value = 0x01
    dut.enc8_1.value = 0x09
    dut.enc8_2.value = 0x11
    dut.enc8_3.value = 0x19
    
    dut.start.value = 1
    await RisingEdge(dut.clk)
    dut.start.value = 0
    
    await RisingEdge(dut.done)
    
    verify_kmac_right_pad(8, [1,9,17,25], dut.right_pad_out)
    print(f"✓ bit_len=8: {dut.right_pad_out.value.hex}")

@cocotb.test()
async def test_kmac_right_pad_vectors(dut):
    """Mehrere bit_len Testvektoren"""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    dut.rst_n.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    
    tests = [
        (0,  [0x01, 0x09, 0x11, 0x19]),   # bit_len=0
        (8,  [0x01, 0x09, 0x11, 0x19]),   # bit_len=8
        (16, [0x02, 0x12, 0x22, 0x32]),   # bit_len=16
        (32, [0x04, 0x24, 0x44, 0x64]),   # bit_len=32
        (63, [0x08, 0x48, 0x88, 0xC8]),   # bit_len=63 (Edge)
    ]
    
    for bit_len, enc8_vals in tests:
        dut.bit_len.value = bit_len
        dut.enc8_0.value = enc8_vals[0]
        dut.enc8_1.value = enc8_vals[1]
        dut.enc8_2.value = enc8_vals[2]
        dut.enc8_3.value = enc8_vals[3]
        
        dut.start.value = 1
        await RisingEdge(dut.clk)
        dut.start.value = 0
        await RisingEdge(dut.done)
        
        verify_kmac_right_pad(bit_len, enc8_vals, dut.right_pad_out)
        print(f"✓ bit_len={bit_len}: OK")

@cocotb.test()
async def test_kmac_right_pad_edge_cases(dut):
    """Edge Cases: bit_len=0, bit_len=64"""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    dut.rst_n.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    
    # Edge Case: bit_len=0
    dut.bit_len.value = 0
    dut.enc8_0.value = 0x01
    dut.start.value = 1
    await RisingEdge(dut.clk)
    dut.start.value = 0
    await RisingEdge(dut.done)
    
    assert dut.right_pad_out.value[0] == 1  # Bit 0 = 1
    print("✓ bit_len=0: OK")
    
    # Edge Case: bit_len=63 (max für 64-bit)
    dut.bit_len.value = 63
    dut.enc8_0.value = 0xFF
    dut.start.value = 1
    await RisingEdge(dut.clk)
    dut.start.value = 0
    await RisingEdge(dut.done)
    
    assert dut.right_pad_out.value[63] == 1  # Bit 63 = 1
    print("✓ bit_len=63: OK")

@pytest.mark.parametrize("bit_len", [0, 8, 16, 32])
@cocotb.test()
async def test_kmac_right_pad_param(dut, bit_len):
    """Parametrisierte Tests"""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    dut.rst_n.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    
    dut.bit_len.value = bit_len
    dut.enc8_0.value = 1
    dut.enc8_1.value = 9
    dut.start.value = 1
    await RisingEdge(dut.clk)
    dut.start.value = 0
    await RisingEdge(dut.done)
    
    verify_kmac_right_pad(bit_len, [1,9,0,0], dut.right_pad_out)
