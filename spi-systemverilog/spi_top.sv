module top (
  input  logic clk_25m,     // 25 MHz Sysclk ULX3S
  input  logic spi_sclk,
  input  logic spi_cs_0,    // SSEL = spi_cs_0 (Haupt-CS)
  input  logic spi_mosi,
  inout  wire spi_miso
);

  logic miso_buf;
  assign spi_miso = miso_buf ? 1'bz : 1'b0;

  SPI_slave u_spi (
    .clk  (clk_25m),
    .SCK  (spi_sclk),
    .SSEL (spi_cs_0),
    .MOSI (spi_mosi),
    .MISO (miso_buf)
  );

endmodule
