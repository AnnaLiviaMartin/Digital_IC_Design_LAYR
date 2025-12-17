module xor (
    input clk,
    input logic [63:0] key,
    input logic [63:0] pad,

    output logic[63:0] result
);

    always @(posedge clk) begin
        result = key ^pad;
    end

endmodule
