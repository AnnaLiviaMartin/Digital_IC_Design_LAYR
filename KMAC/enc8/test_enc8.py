import cocotb
import pytest
from cocotb.triggers import Timer

@cocotb.test()
async def test_enc8_identity(dut):
    """enc8(x): x ∈ {0,...,255} → 8-bit string representing x"""
    dut.x.value = 0 
    print("Testing enc8(x) = x for all x ∈ {0,...,255}")
    
    test_vectors = [
        (0x00, 0x00), (0x01, 0x01), (0x42, 0x42), (0x7F, 0x7F),
        (0x80, 0x80), (0xAA, 0xAA), (0xFF, 0xFF), (0x10, 0x10),
        (0x20, 0x20), (0x64, 0x64), (0xC0, 0xC0), (0xE1, 0xE1),
    ]
    
    for x_val, expected_enc8 in test_vectors:
        dut.x.value = x_val
        await Timer(1, unit="ns")  # Warten auf Kombinatorik-Propagation
        
        val = dut.enc8_out.value
        assert val.is_resolvable, f"Unresolved bei x=0x{x_val:02x}: {val.binstr}"
        
        actual_enc8 = val.to_unsigned()
        assert actual_enc8 == expected_enc8, \
            f"enc8(0x{x_val:02x}) = 0x{actual_enc8:02x} != 0x{expected_enc8:02x}"
        
        print(f"✓ enc8(0x{x_val:02x}) = 0x{actual_enc8:02x}")


@cocotb.test()
async def test_enc8_full_range(dut):
    """Testet ALLE 256 Werte x ∈ {0,...,255}"""
    dut.x.value = 0 
    print("Full range test: 256 values...")
    errors = 0
    
    for x in range(256):
        dut.x.value = x
        await Timer(0.1, unit="ns")  # Minimale Wartezeit für schnelle Propagation
        
        val = dut.enc8_out.value
        if not val.is_resolvable:
            errors += 1
            print(f"✗ Unresolved bei x={x}: {val.binstr}")
            continue
            
        enc8_val = val.to_unsigned()
        if enc8_val != x:
            errors += 1
            print(f"✗ enc8({x:3d}) = 0x{enc8_val:02x} != 0x{x:02x}")
    
    assert errors == 0, f"{errors}/256 tests failed!"
    print("✓ enc8(x): FULL RANGE (0-255) CORRECT!")


@cocotb.test()
async def test_enc8_context(dut):
    """KMAC enc8(0)||enc8(1)||enc8(2)... für Padding"""
    
    kmac_sequence = [i for i in range(8)]
    
    for i, expected in enumerate(kmac_sequence):
        dut.x.value = i
        await Timer(1, unit="ns")
        
        val = dut.enc8_out.value
        assert val.is_resolvable, f"KMAC unresolved bei x={i}: {val.binstr}"
        
        actual = val.to_unsigned()
        assert actual == expected, \
            f"KMAC enc8({i}) = 0x{actual:02x} != 0x{expected:02x}"
        
        print(f"✓ KMAC enc8({i}) = 0x{i:02x}")


@pytest.mark.parametrize("x_val,expected", [
    (0, 0x00), (42, 0x2A), (255, 0xFF)
])
@cocotb.test()
async def test_enc8_parametrized(dut, x_val, expected):
    """Parametrisierte Tests"""
    dut.x.value = 0 
    dut.x.value = x_val
    await Timer(1, unit="ns")
    
    val = dut.enc8_out.value
    assert val.is_resolvable, f"Parametrized unresolved bei x={x_val}: {val.binstr}"
    
    actual = val.to_unsigned()
    assert actual == expected, f"enc8({x_val}) = 0x{actual:02x} != 0x{expected:02x}"
    print(f"✓ enc8({x_val:3d}) = 0x{expected:02x}")
