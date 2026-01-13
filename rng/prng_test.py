import cocotb

from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

@cocotb.test()
async def test_random_numbers_prng(dut) -> None :
    clock = Clock(dut.clk, 10, unit = 'ns')
    cocotb.start_soon(clock.start())

    await RisingEdge(dut.clk)

    random_numbers = []

    for i in range(10_000) :

        await RisingEdge(dut.clk)
        
        random = dut.random.value

        if random in random_numbers:
            raise Exception(f"random number duplication at index {i}, number: {random}")
        
        random_numbers.append(random)
 