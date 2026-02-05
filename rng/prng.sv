`timescale 1ns/1ps

module prng (
    input logic clk,
    output logic [255 : 0] random
);

localparam seed = 256'h1;

logic [255 : 0] lfsr = seed;
logic [0 : 0] feedback;

always_ff @(posedge clk) begin
    feedback = lfsr[255] ^ lfsr[9] ^ lfsr[4] ^ lfsr[1] ^ lfsr[0];
    lfsr = {lfsr[254 : 0], feedback};
    random = lfsr;
end

endmodule
