`include "config.sv"
`timescale 1ns / 1ps

module xor_begin
    import ascon_pkg::t_state_array;
(
    input  t_state_array         i_state,            //! Input State Array
    input  logic         [ 63:0] i_data,             //! Input Data to XOR
    input  logic         [127:0] i_key,              //! Input Key to XOR
    input  logic                 i_enable_xor_key,   //! Enable XOR with Key, active high
    input  logic                 i_enable_xor_data,  //! Enable XOR with Data, active high
    output t_state_array         o_state             //! Output State Array
);

    assign o_state[0] = i_enable_xor_data ? (i_state[0] ^ i_data) : i_state[0];
    assign o_state[1] = i_enable_xor_key ? (i_state[1] ^ i_key[127:64]) : i_state[1];
    assign o_state[2] = i_enable_xor_key ? (i_state[2] ^ i_key[63:0]) : i_state[2];
    assign o_state[3] = i_state[3];
    assign o_state[4] = i_state[4];

endmodule