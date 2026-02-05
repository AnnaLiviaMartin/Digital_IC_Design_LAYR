`include "config.sv"
`timescale 1ns / 1ps

module xor_end
    import ascon_pkg::t_state_array;
(
    input  t_state_array         i_state,           //! Input State Array
    input  logic         [127:0] i_key,             //! Input Key to XOR
    input  logic                 i_enable_xor_key,  //! Enable XOR with Key, active high
    input  logic                 i_enable_xor_lsb,  //! Enable XOR with LSB, active high
    output t_state_array         o_state            //! Output State Array
);

    // Signals declaration
    logic [63:0] state_part_4_xored_with_lsb;  //! Signal to store the 4th part of the state xor-ed with the LSB

    // Xor the 4th part of the state with the LSB
    assign state_part_4_xored_with_lsb = {i_state[4][63:1], i_state[4][0] ^ i_enable_xor_lsb};

    assign o_state[0] = i_state[0];
    assign o_state[1] = i_state[1];
    assign o_state[2] = i_state[2];
    assign o_state[3] = i_enable_xor_key ? (i_state[3] ^ i_key[127:64]) : i_state[3];
    assign
        o_state[4] = i_enable_xor_key ? (state_part_4_xored_with_lsb ^ i_key[63:0]) : state_part_4_xored_with_lsb;

endmodule