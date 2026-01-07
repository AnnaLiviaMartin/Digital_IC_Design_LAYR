import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

@cocotb.test()
async def test_kmac_idle(dut):
    dut._log.info("Testing IDLE state")
    clock = Clock(dut.clk, 10, units='ns')
    cocotb.start_soon(clock.start())
    await RisingEdge(dut.clk)
    assert int(dut.state) == 0

@cocotb.test()
async def test_kmac_reset(dut):
    clock = Clock(dut.clk, 10, units='ns')
    cocotb.start_soon(clock.start())
    dut.rst_n <= 0
    await RisingEdge(dut.clk)
    assert int(dut.state) == 0
    dut.rst_n <= 1
    await RisingEdge(dut.clk)

@cocotb.test()
async def test_kmac_start_transition(dut):
    clock = Clock(dut.clk, 10, units='ns')
    cocotb.start_soon(clock.start())
    dut.rst_n <= 0
    await RisingEdge(dut.clk)
    dut.rst_n <= 1
    await RisingEdge(dut.clk)
    
    assert int(dut.state) == 0
    
    dut.start <= 1
    dut.key <= 0x0123456789abcdef0123456789abcdef  # Python hex (0x)
    await RisingEdge(dut.clk)
    
    assert int(dut.state) == 1
