`include "config.sv"
`timescale 1ns / 1ps

// first round constant addition layer pc
module addition_layer
    import ascon_pkg::t_state_array, ascon_pkg::C_LUT_ADDITION;
(
    input  logic         [3:0] i_round,  //! Input round number, used to select round constant
    input  t_state_array       i_state,
    output t_state_array       o_state
);

    assign o_state[0] = i_state[0];
    assign o_state[1] = i_state[1];
    assign o_state[2] = i_state[2] ^ {56'h00000000000000, C_LUT_ADDITION[i_round]};
    assign o_state[3] = i_state[3];
    assign o_state[4] = i_state[4];

endmodule
