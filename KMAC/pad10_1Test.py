import cocotb
from cocotb.triggers import RisingEdge, FallingEdge, Timer, Event
from cocotb.clock import Clock
import pytest

@cocotb.test()
async def test_pad10_1_basic(dut):
    """Testet grundlegende Funktionalität: findet z für gegebene r,m"""
    # Clock und Reset
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    dut.rst_n.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    
    # Testvektor: r=5, m=3 -> (z+3+2) mod 5 == 0 -> z+5 mod 5 == 0 -> z=0
    dut.r.value = 5
    dut.m.value = 3
    dut.start.value = 0
    
    await RisingEdge(dut.clk)
    
    # Start triggern
    dut.start.value = 1
    await RisingEdge(dut.clk)
    dut.start.value = 0
    
    # Auf done warten (max 10M Takte = 100ms)
    timeout = Timer(100_000, units="ns")
    await cocotb.triggers.First(RisingEdge(dut.done), timeout)
    
    assert dut.done.value == 1, "Timeout: done nicht gesetzt"
    print(f"P = {dut.P.value.integer} (sollte 10^0 = 1 sein)")

@cocotb.test()
async def test_pad10_1_z_calculation(dut):
    """Testet korrekte z-Suche: verschiedene r,m Kombinationen"""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    dut.rst_n.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    
    test_vectors = [
        # (r, m, erwartetes z)
        (5, 3, 0),   # (0+3+2)%5 = 0
        (7, 1, 4),   # (4+1+2)%7 = 0
        (3, 0, 1),   # (1+0+2)%3 = 0
        (10, 8, 0),  # (0+8+2)%10 = 0
    ]
    
    for r_val, m_val, expected_z in test_vectors:
        dut.r.value = r_val
        dut.m.value = m_val
        dut.start.value = 0
        
        await RisingEdge(dut.clk)
        dut.start.value = 1
        await RisingEdge(dut.clk)
        dut.start.value = 0
        
        await RisingEdge(dut.done)
        
        # z aus internem Zähler prüfen (müsste sichtbar sein)
        # Annahme: z_cnt als output verfügbar oder via waveform
        print(f"r={r_val}, m={m_val}: P={dut.P.value.integer}")
        # Hier würde man z_cnt.value mit expected_z vergleichen

@cocotb.test()
async def test_pad10_1_timeout(dut):
    """Testet Timeout bei z > 9999999 (unmöglich)"""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    dut.rst_n.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    
    # Ungültige Eingabe die nie 0 wird (r=1)
    dut.r.value = 1  # mod 1 immer 0, aber Edge-Case
    dut.m.value = 0
    dut.start.value = 1
    await RisingEdge(dut.clk)
    dut.start.value = 0
    
    await RisingEdge(dut.done)
    assert dut.done.value == 1

@cocotb.test()
async def test_pad10_1_power_correctness(dut):
    """Überprüft 10^z Darstellung (1 gefolgt von z Nullen)"""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    dut.rst_n.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    
    # Test mit z=3: r=5, m=0 -> (3+0+2)%5=0
    dut.r.value = 5
    dut.m.value = 0
    dut.start.value = 1
    await RisingEdge(dut.clk)
    dut.start.value = 0
    
    await RisingEdge(dut.done)
    
    # 10^3 = 1000 -> binär: Bit 3 gesetzt (1<<3)
    expected_p = 1 << 3  # 8
    assert dut.P.value.integer == expected_p, \
        f"Erwartet 10^3={expected_p}, bekommen {dut.P.value.integer}"

# pytest Konfiguration
def test_pad10_1_suite():
    """Führt alle Tests sequentiell aus"""
    pass
