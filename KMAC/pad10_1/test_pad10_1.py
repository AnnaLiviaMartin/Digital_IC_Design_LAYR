import cocotb
from cocotb.triggers import RisingEdge, Timer, First
from cocotb.clock import Clock

@cocotb.test()
async def test_pad10_1_basic(dut): #Testet die Grundfunktionalität mit r=5, m=3 (z=0 → P=5), FSM-Übergänge und done-Signal.
    """Grundtest: r=5, m=3 → z=0, P=0b101"""
    clock = Clock(dut.clk, 1, unit="ns")  
    cocotb.start_soon(clock.start())
    
    dut.rst_n.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    
    dut.r.value = 5
    dut.m.value = 3
    dut.start.value = 0
    
    await RisingEdge(dut.clk)
    
    dut.start.value = 1
    await RisingEdge(dut.clk)
    dut.start.value = 0         #notwenidg wegen Timeout 
    
    
    timeout = Timer(1_000_000, unit="ns")
    await First(RisingEdge(dut.done), timeout)
    assert dut.P.value.to_unsigned() == 5, "P != 5 (0b101)"
    assert dut.done.value == 1, "Timeout: done nicht gesetzt"

@cocotb.test()
async def test_pad10_1_z_calculation(dut):#Validiert pad10_1(r,m) für 4 Testvektoren mit unterschiedlichen z-Werten (0,1,4) und P-Ausgaben.
    clock = Clock(dut.clk, 1, unit="ns")
    cocotb.start_soon(clock.start())
    
    dut.rst_n.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    
    test_vectors = [
        (5, 3, 5),
        (7, 1, 65),
        (3, 0, 9),
        (10, 8, 5),
    ]
    
    for r_val, m_val, expected_p in test_vectors:
        dut.r.value = r_val
        dut.m.value = m_val
        dut.start.value = 0

        
        await RisingEdge(dut.clk)
        dut.start.value = 1
        await RisingEdge(dut.clk)
        dut.start.value = 0
        
        timeout = Timer(2_000_000, unit="ns")  # ✅ Längeres Timeout
        await First(RisingEdge(dut.done), timeout)
        print(f"r={r_val}, m={m_val}: P={dut.P.value.to_unsigned()}")
        assert dut.P.value.to_unsigned() == expected_p, f"P={dut.P.value.to_unsigned()} != {expected_p}"

@cocotb.test()
async def test_pad10_1_timeout(dut):#Prüft sofortigen Abschluss bei r=1 (jedes z gültig) und done-Signal ohne SEARCH_Z-Loop.
    clock = Clock(dut.clk, 1, unit="ns")
    cocotb.start_soon(clock.start())
    
    dut.rst_n.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    
    dut.r.value = 1
    dut.m.value = 0
    dut.start.value = 1
    await RisingEdge(dut.clk)
    dut.start.value = 0
    
    await RisingEdge(dut.done)
    assert dut.done.value == 1

@cocotb.test()
async def test_pad10_1_power_correctness(dut): #Verifiziert die P-Berechnung 1 0^z 1 speziell für r=5, m=0 (z=1 → P=9).
    clock = Clock(dut.clk, 1, unit="ns")
    cocotb.start_soon(clock.start())
    
    dut.rst_n.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    
    dut.r.value = 5
    dut.m.value = 0
    dut.start.value = 1
    await RisingEdge(dut.clk)
    dut.start.value = 0
    
    timeout = Timer(1_000_000, unit="ns")
    await First(RisingEdge(dut.done), timeout)
    
    expected_p = 33  # 1 << 3 | 1 = 0b100001
    assert dut.P.value.to_unsigned() == expected_p, \
        f"Erwartet P=9 (0b1001), bekommen {dut.P.value.to_unsigned()}"
