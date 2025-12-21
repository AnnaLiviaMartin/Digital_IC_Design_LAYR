import cocotb
from cocotb.triggers import RisingEdge, Timer, First
from cocotb.clock import Clock

@cocotb.test()
async def test_pad10_1_basic(dut):
    """Grundtest: r=5, m=3 → z=0, P=0b11"""
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
    #dut.start.value = 0
    
    # ✅ FIX: 1ms Timeout (1_000_000 ns)
    timeout = Timer(1_000_000, unit="ns")
    await First(RisingEdge(dut.done), timeout)
    print("xxxxxxxxxxxxxxxxxxxxxxxxxx")
    print(f"Done = {dut.done.value}")
    print(f"P = {dut.P.value}")
    print(f"Z_cnt = {dut.z_cnt.value}")

    assert dut.P.logic_array.to_unsigned() == 5 #extra
    assert dut.done.value == 1, "Timeout: done nicht gesetzt"

@cocotb.test()
async def test_pad10_1_z_calculation(dut):
    clock = Clock(dut.clk, 1, unit="ns")  # ✅ 1ns!
    cocotb.start_soon(clock.start())
    
    dut.rst_n.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    
    test_vectors = [
        (5, 3, 0),
        (7, 1, 4),
        (3, 0, 1),
        (10, 8, 0),
    ]
    
    for r_val, m_val, expected_z in test_vectors:
        dut.r.value = r_val
        dut.m.value = m_val
        dut.start.value = 0
        
        await RisingEdge(dut.clk)
        dut.start.value = 1
        await RisingEdge(dut.clk)
        dut.start.value = 0
        
        timeout = Timer(2_000_000, unit="ns")  # ✅ Längeres Timeout
        await First(RisingEdge(dut.done), timeout)
        print(f"r={r_val}, m={m_val}: P={dut.P.value.integer}")

@cocotb.test()
async def test_pad10_1_timeout(dut):
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
async def test_pad10_1_power_correctness(dut):
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
    
    expected_p = 3  # 1 << 0 | 1 = 0b11
    assert dut.P.value.integer == expected_p, \
        f"Erwartet P=3 (0b11), bekommen {dut.P.value.integer}"
