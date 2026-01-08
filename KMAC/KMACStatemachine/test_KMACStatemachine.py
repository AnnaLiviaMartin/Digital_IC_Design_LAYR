import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

async def reset_dut(dut):
    cocotb.start_soon(Clock(dut.clk, 10, units='ns').start())
    await Timer(20, unit='ns')  # Clock starten lassen
    dut.rst_n.value = 0
    await Timer(100, unit='ns')  # Langer Reset-Puls (10 Clocks)
    dut.rst_n.value = 1
    await Timer(50, unit='ns')   # Nach-Reset-Settling
    dut._log.info(f"Post-reset state: {dut.state.value}")


@cocotb.test()
async def test_kmac_idle(dut):
    dut._log.info("Testing IDLE state")
    clock = Clock(dut.clk, 10, unit='ns')
    cocotb.start_soon(clock.start())
    await reset_dut(dut)
    dut._log.info(f"state.value: {dut.state.value}")  # Debug: Zeigt '00000' oder 'XXXXX'
    assert str(dut.state.value) == '00000'  # Oder dut.state.value == '00000'



@cocotb.test()
async def test_kmac_reset(dut):
    clock = Clock(dut.clk, 10, unit='ns')  # 'unit' -> 'units'
    cocotb.start_soon(clock.start())
    dut.rst_n.value = 0  # Modern: .value =
    await RisingEdge(dut.clk)
    assert str(dut.state.value) == '00000'  # String-Vergleich gegen X
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)


@cocotb.test()
async def test_kmac_start_transition(dut):
    clock = Clock(dut.clk, 10, unit='ns')
    cocotb.start_soon(clock.start())
    dut.rst_n.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)  # IDLE bestätigen
    
    assert str(dut.state.value) == '00000'
    
    # start PULS: setup vor Edge, check nach NEXT Edge
    dut.start.value = 1
    dut.key.value = 0x0123456789abcdef0123456789abcdef
    await RisingEdge(dut.clk)  # start sampled -> state_next = KEY_BYTEPAD
    dut.start.value = 0  # Puls beenden (optional, aber sauber)
    
    await RisingEdge(dut.clk)  # state <= state_next (jetzt 1)
    
    assert str(dut.state.value) == '00001'  # KEY_BYTEPAD


