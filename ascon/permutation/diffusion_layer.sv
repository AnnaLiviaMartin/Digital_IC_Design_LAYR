`include "config.sv"
`timescale 1ns / 1ps

module diffusion_layer
    import ascon_pkg::t_state_array;
(
    input  t_state_array i_state,
    output t_state_array o_state
);

    assign o_state[0] = i_state[0] ^ {i_state[0][18:0], i_state[0][63:19]} ^ {i_state[0][27:0], i_state[0][63:28]};
    assign o_state[1] = i_state[1] ^ {i_state[1][60:0], i_state[1][63:61]} ^ {i_state[1][38:0], i_state[1][63:39]};
    assign o_state[2] = i_state[2] ^ {i_state[2][0], i_state[2][63:1]} ^ {i_state[2][5:0], i_state[2][63:6]};
    assign o_state[3] = i_state[3] ^ {i_state[3][9:0], i_state[3][63:10]} ^ {i_state[3][16:0], i_state[3][63:17]};
    assign o_state[4] = i_state[4] ^ {i_state[4][6:0], i_state[4][63:7]} ^ {i_state[4][40:0], i_state[4][63:41]};

endmodule
