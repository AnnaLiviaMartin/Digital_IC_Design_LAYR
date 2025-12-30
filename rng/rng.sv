module rng (
    input clk,
    output [255 : 0] random
);

localparam seed = 256'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

logic [255 : 0] lfsr = seed;
logic [255 : 0] feedback;

always_ff @(posedge clk) begin
    feedback <= lfsr[255] ^ lfsr[254] ^ lfsr[252] ^ lfsr[251];
    lfsr <= {feedback, lfsr[255:1]};
    random <= lfsr;
end

endmodule
