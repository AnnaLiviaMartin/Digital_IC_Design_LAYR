module top (
  input  logic clk_25m,
  input  logic spi_sclk,
  input  logic spi_cs_0,
  input  logic spi_mosi,
  output wire spi_miso,
  output logic [7:0] leds
);

  SPI_slave u_spi (
    .clk(clk_25m),
    .SCK(spi_sclk),
    .SSEL(spi_cs_0),
    .MOSI(spi_mosi),
    .MISO(spi_miso),
    .LEDS(leds)
  );

endmodule
