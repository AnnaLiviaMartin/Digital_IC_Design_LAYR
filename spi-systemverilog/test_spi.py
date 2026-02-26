import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

SPI_HALF_PERIOD_NS = 100

async def spi_transfer(dut, tx_byte: int) -> int:
    rx_bits = []
    dut.spi_cs_0.value = 0
    
    for i in range(8):
        bit = (tx_byte >> (7 - i)) & 1
        dut.spi_mosi.value = bit
        dut.spi_sclk.value = 0
        await Timer(SPI_HALF_PERIOD_NS, unit="ns")
        dut.spi_sclk.value = 1
        await Timer(SPI_HALF_PERIOD_NS, unit="ns")
        dut.spi_sclk.value = 0
        await Timer(SPI_HALF_PERIOD_NS, unit="ns")
        rx_bits.append(int(dut.spi_miso.value))
    
    dut.spi_cs_0.value = 1
    await Timer(SPI_HALF_PERIOD_NS * 2, unit="ns")
    
    return sum(b << (7-i) for i,b in enumerate(rx_bits))

@cocotb.test()
async def test_spi_response(dut):
    # ALLE Signale initialisieren
    dut.clk_25m.value = 0
    dut.spi_sclk.value = 0
    dut.spi_cs_0.value = 1
    dut.spi_mosi.value = 0
    
    # Clock starten
    cocotb.start_soon(Clock(dut.clk_25m, 40, unit="ns").start())
    
    # LÄNGERER Reset (für alle FFs)
    for _ in range(50):
        await RisingEdge(dut.clk_25m)
    
    # SPI Signale nochmal sicherstellen
    dut.spi_sclk.value = 0
    dut.spi_cs_0.value = 1
    dut.spi_mosi.value = 0
    
    # Jetzt testen
    await spi_transfer(dut, 0x12)
    rx = await spi_transfer(dut, 0x00)
    
    assert rx == 0x04, f"Expected 0x04, got 0x{rx:02x}"
    print(f"✅ SPI OK: 0x{rx:02x}, LEDs=0b{dut.leds.value.integer:08b}")
