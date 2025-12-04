`include "config.sv"
`timescale 1ns / 1ps

module substitution_layer
    import ascon_pkg::t_state_array;
#(
    parameter int G_NUM_SBOXES = 64  //! Number of SBOXES in the Substitution Layer
) (
    input  t_state_array i_state,
    output t_state_array o_state
);

    //
    // Generate and instantiate SBOXES
    //

    for (genvar i = 0; i < G_NUM_SBOXES; i = i + 1) begin : g_sbox
        sbox sbox_i (
            .i_data({i_state[0][i], i_state[1][i], i_state[2][i], i_state[3][i], i_state[4][i]}),
            .o_data({o_state[0][i], o_state[1][i], o_state[2][i], o_state[3][i], o_state[4][i]})
        );
    end

endmodule
