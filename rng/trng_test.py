import cocotb

@cocotb.test()
async def print_trng(dut) -> None :
    
    for _ in range(10):
        random = dut.random.value
        cocotb.log.info("random is %s", random)

