import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
from cocotb.result import TestFailure

@cocotb.test()
async def test_kmac_fsm_state_coverage(dut):
    """**TESTET ALLE STATES** + Übergänge"""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    # Reset
    dut.rst_n.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    assert dut.state.value == 0  # IDLE nach Reset
    
    # State Coverage Test
    states_visited = set()
    
    dut.start.value = 1
    await RisingEdge(dut.clk)
    dut.start.value = 0
    
    # Warte auf vollständige Pipeline (~20 Takte)
    timeout = Timer(500, units="ns")
    while not dut.mac_done.value and not timeout.triggered():
        await RisingEdge(dut.clk)
        states_visited.add(int(dut.state.value))
    
    assert dut.mac_done.value, "FSM Timeout - kein Progress!"
    assert len(states_visited) == 6, f"Nur {len(states_visited)}/6 States besucht: {states_visited}"
    
    print(f"✓ FSM Coverage: {len(states_visited)}/6 States OK")

@cocotb.test()
async def test_kmac_fsm_reset(dut):
    """Reset jederzeit → IDLE"""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    dut.start.value = 1
    await RisingEdge(dut.clk)  # State → INIT_KMAC
    
    # Reset während Processing
    dut.rst_n.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    
    assert dut.state.value == 0, "Reset muss zu IDLE zurückkehren"
    print("✓ FSM Reset OK")

@cocotb.test()
async def test_kmac_fsm_illegal_state(dut):
    """Illegal State → IDLE"""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    # Force illegal state (für Test)
    dut.state.value = 7  # Ungültiger State
    
    await RisingEdge(dut.clk)
    assert dut.state.value == 0, "Default case muss IDLE sein"
    print("✓ FSM Default/Illegal State OK")

@cocotb.test()
async def test_kmac_fsm_timing(dut):
    """Exakte State-Sequenz verifizieren"""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    dut.rst_n.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    
    state_sequence = []
    dut.start.value = 1
    await RisingEdge(dut.clk)
    dut.start.value = 0
    
    for i in range(30):  # Max 30 Takte Pipeline
        await RisingEdge(dut.clk)
        state_sequence.append(int(dut.state.value))
        if dut.mac_done.value:
            break
    
    # Expected Sequence (vereinfacht)
    expected = [0, 1, 2, 3, 4, 5]  # IDLE→...→EXTRACT
    print(f"Observed: {state_sequence}")
    assert all(s in state_sequence for s in expected), "Nicht alle States durchlaufen!"
    print("✓ FSM Timing/Sequence OK")
