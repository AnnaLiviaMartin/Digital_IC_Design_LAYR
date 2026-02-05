`include "config.sv"
`timescale 1ns / 1ps

module sbox
    import ascon_pkg::C_LUT_SBOX;
(
    input  logic unsigned [4:0] i_data,
    output logic          [4:0] o_data
);

    assign o_data[4:0] = C_LUT_SBOX[i_data][4:0];

endmodule
