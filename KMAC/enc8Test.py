import cocotb
from cocotb.triggers import Timer
from cocotb.result import TestFailure
import pytest

@cocotb.test()
async def test_enc8_identity(dut):
    """enc8(x): x ∈ {0,...,255} → 8-bit string representing x"""
    
    print("Testing enc8(x) = x for all x ∈ {0,...,255}")
    
    # Test 16 repräsentative Werte (schnell)
    test_vectors = [
        (0x00, 0x00), (0x01, 0x01), (0x42, 0x42), (0x7F, 0x7F),
        (0x80, 0x80), (0xAA, 0xAA), (0xFF, 0xFF), (0x10, 0x10),
        (0x20, 0x20), (0x64, 0x64), (0xC0, 0xC0), (0xE1, 0xE1),
    ]
    
    for x_val, expected_enc8 in test_vectors:
        dut.x.value = x_val
        await Timer(1, units="ns")
        
        actual_enc8 = dut.enc8_out.value.integer
        
        assert actual_enc8 == expected_enc8, \
            f"enc8(0x{x_val:02x}) = 0x{actual_enc8:02x} != 0x{expected_enc8:02x}"
        
        print(f"✓ enc8(0x{x_val:02x}) = 0x{actual_enc8:02x}")

@cocotb.test()
async def test_enc8_full_range(dut):
    """Testet ALLE 256 Werte x ∈ {0,...,255}"""
    
    print("Full range test: 256 values...")
    errors = 0
    
    for x in range(256):
        dut.x.value = x
        await Timer(1, units="ns")
        
        enc8_val = dut.enc8_out.value.integer
        if enc8_val != x:
            errors += 1
            print(f"✗ enc8({x:3d}) = 0x{enc8_val:02x} != 0x{x:02x}")
    
    assert errors == 0, f"{errors}/256 tests failed!"
    print("✓ enc8(x): FULL RANGE (0-255) CORRECT!")

@cocotb.test()
async def test_enc8_kmac_context(dut):
    """KMAC enc8(0)||enc8(1)||enc8(2)... für Padding"""
    
    # Erste 8 Bytes von KMAC right-pad
    kmac_sequence = [i for i in range(8)]
    
    for i, expected in enumerate(kmac_sequence):
        dut.x.value = i
        await Timer(1, units="ns")
        
        actual = dut.enc8_out.value.integer
        assert actual == expected, \
            f"KMAC enc8({i}) = 0x{actual:02x} != 0x{expected:02x}"
        
        print(f"✓ KMAC enc8({i}) = 0x{i:02x}")

# pytest parametrized Tests
@pytest.mark.parametrize("x_val,expected", [
    (0, 0x00), (42, 0x2A), (255, 0xFF)
])
@cocotb.test()
async def test_enc8_parametrized(dut, x_val, expected):
    """Parametrisierte Tests"""
    dut.x.value = x_val
    await Timer(1, units="ns")
    
    assert dut.enc8_out.value.integer == expected, \
        f"enc8({x_val}) failed"
    print(f"✓ enc8({x_val:3d}) = 0x{expected:02x}")
