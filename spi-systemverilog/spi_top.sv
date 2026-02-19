module top (
  input  logic clk_25m,     // 25 MHz Sysclk ULX3S
  input  logic spi_sclk,
  input  logic spi_cs_0,    // SSEL = spi_cs_0 (Haupt-CS)
  input  logic spi_mosi,
  output wire spi_miso
  output logic LED;
);

  SPI_slave u_spi (
    .clk  (clk_25m),
    .SCK  (spi_sclk),
    .SSEL (spi_cs_0),
    .MOSI (spi_mosi),
    .MISO (spi_miso),
    .LED  (LED)
  );

endmodule
