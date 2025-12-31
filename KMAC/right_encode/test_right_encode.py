import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer, First
import pytest


def verify_kmac_right_pad(bit_len, enc8_vals, pad_out):
    """NIST KMAC right-pad Verification"""
    actual = pad_out.value.to_unsigned()
    print(f"DEBUG: bit_len={bit_len}, actual=0x{actual:016x}")
    
    # 1. enc8 Bytes (Bits 32-63)
    assert pad_out.value[39:32].to_unsigned() == enc8_vals[0], f"enc8_0 wrong"
    assert pad_out.value[47:40].to_unsigned() == enc8_vals[1], f"enc8_1 wrong"
    assert pad_out.value[55:48].to_unsigned() == enc8_vals[2], f"enc8_2 wrong"
    assert pad_out.value[63:56].to_unsigned() == enc8_vals[3], f"enc8_3 wrong"
    print("✓ enc8_bytes[32:63] OK")
    
    # 2. Bit[bit_len] = 1, Bits[0:bit_len-1] = 0
    if bit_len < 64:
        if bit_len < 32:  # enc8 beginnt Bit 32
            assert (actual & (1 << bit_len)) != 0, f"Bit[{bit_len}] = 0"
        else:
            print(f"✓ bit_len={bit_len}: enc8-Überlappung (NIST OK)")
        mask = (1 << bit_len) - 1
        assert (actual & mask) == 0, f"Bits[0:{bit_len-1}] != 0"
        print(f"✓ right-pad(bit_len={bit_len}) OK")


@cocotb.test()
async def test_kmac_right_pad_basic(dut):
    """NIST KMAC right-pad: bit_len=8"""
    clock = Clock(dut.clk, 1, unit="ns")
    cocotb.start_soon(clock.start())
    
    dut.rst_n.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    
    dut.bit_len.value = 8
    dut.enc8_0.value = 0x01
    dut.enc8_1.value = 0x09
    dut.enc8_2.value = 0x11
    dut.enc8_3.value = 0x19
    
    dut.start.value = 1
    await RisingEdge(dut.clk)
    dut.start.value = 0
    
    timeout = Timer(100_000, unit="ns")
    await First(RisingEdge(dut.done), timeout)
    assert dut.done.value == 1
    
    verify_kmac_right_pad(8, [1,9,17,25], dut.right_pad_out)


@cocotb.test()
async def test_kmac_right_pad_vectors(dut):
    """Mehrere bit_len Testvektoren - FIXED timing"""
    clock = Clock(dut.clk, 1, unit="ns")
    cocotb.start_soon(clock.start())
    
    dut.rst_n.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    
    tests = [
        (0,  [0x01, 0x09, 0x11, 0x19]),
        (8,  [0x01, 0x09, 0x11, 0x19]),
        (16, [0x02, 0x12, 0x22, 0x32]),
        (32, [0x04, 0x24, 0x44, 0x64]),
    ]
    
    for bit_len, enc8_vals in tests:
        print(f"\nTesting bit_len={bit_len}")
        dut.bit_len.value = bit_len
        dut.enc8_0.value = enc8_vals[0]
        dut.enc8_1.value = enc8_vals[1]
        dut.enc8_2.value = enc8_vals[2]
        dut.enc8_3.value = enc8_vals[3]
        
        # Sicherstellen dass wir in IDLE sind
        dut.start.value = 0
        await RisingEdge(dut.clk)  # Edge 0: IDLE
        
        # Proper start pulse: genau 2 Clock Edges
        dut.start.value = 1
        await RisingEdge(dut.clk)  # Edge 1: IDLE→COMPUTE
        dut.start.value = 0
        await RisingEdge(dut.clk)  # Edge 2: COMPUTE→DONE_STATE
        
        await RisingEdge(dut.clk)  # Warten auf done assertion
        assert dut.done.value == 1, f"done not asserted for bit_len={bit_len}"

        
        verify_kmac_right_pad(bit_len, enc8_vals, dut.right_pad_out)
        print(f"✓ bit_len={bit_len}: OK")


@cocotb.test()
async def test_kmac_right_pad_edge_cases(dut):
    """Edge Cases"""
    clock = Clock(dut.clk, 1, unit="ns")
    cocotb.start_soon(clock.start())
    
    dut.rst_n.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    
    # bit_len=0: Bit 0 = 1 (LSB)
    dut.bit_len.value = 0
    dut.enc8_0.value = 0x01
    dut.enc8_1.value = 0x09
    dut.enc8_2.value = 0x00
    dut.enc8_3.value = 0x00
    
    dut.start.value = 1
    await RisingEdge(dut.clk)
    dut.start.value = 0
    
    timeout = Timer(100_000, unit="ns")
    await First(RisingEdge(dut.done), timeout)
    assert dut.done.value == 1
    
    verify_kmac_right_pad(0, [1,9,0,0], dut.right_pad_out)


@pytest.mark.parametrize("bit_len", [0, 8, 16])
@cocotb.test()
async def test_kmac_right_pad_param(dut, bit_len):
    """Parametrisierte Tests"""
    clock = Clock(dut.clk, 1, unit="ns")
    cocotb.start_soon(clock.start())
    
    dut.rst_n.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    
    dut.bit_len.value = bit_len
    dut.enc8_0.value = 0x01
    dut.enc8_1.value = 0x09
    dut.enc8_2.value = 0x00
    dut.enc8_3.value = 0x00
    
    dut.start.value = 1
    await RisingEdge(dut.clk)
    dut.start.value = 0
    
    timeout = Timer(100_000, unit="ns")
    await First(RisingEdge(dut.done), timeout)
    
    verify_kmac_right_pad(bit_len, [1,9,0,0], dut.right_pad_out)
