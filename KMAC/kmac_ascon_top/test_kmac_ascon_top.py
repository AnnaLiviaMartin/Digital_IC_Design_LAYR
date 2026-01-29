import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

@cocotb.test()
async def test_top_state_transitions(dut):
    clock = Clock(dut.clk, 10, unit="ns")  # units statt unit
    cocotb.start_soon(clock.start())
    
    # Reset
    dut.rst_n.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)
    
    print("✓ IDLE nach Reset")
    assert int(dut.top_state.value) == 0
    
    # 1. ASCON: IDLE→2
    print("-- TEST ASCON --")
    dut.hash_start.value = 1
    await RisingEdge(dut.clk)
    dut.hash_start.value = 0
    await RisingEdge(dut.clk)
    assert int(dut.top_state.value) == 2
    print(f"✓ ASCON top_state={int(dut.top_state.value)}")
    
    # 2. KMAC: ASCON→KMAC (2→1)
    print("-- TEST KMAC --")
    dut.kmac_start.value = 1
    await RisingEdge(dut.clk)
    dut.kmac_start.value = 0
    await RisingEdge(dut.clk)
    assert int(dut.top_state.value) == 1  # Jetzt PASS!
    print(f"✓ KMAC top_state={int(dut.top_state.value)}")

@cocotb.test()
async def test_top_reset(dut):
    clock = Clock(dut.clk, 10, unit="ns")
    cocotb.start_soon(clock.start())
    dut.rst_n.value = 0
    await RisingEdge(dut.clk)
    assert int(dut.top_state.value) == 0
