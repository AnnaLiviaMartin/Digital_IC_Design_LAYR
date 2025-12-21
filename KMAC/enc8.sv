module enc8_kmac (
    input  logic [7:0] x,        // x ∈ {0,...,255}
    output logic [7:0] enc8_out  // 8-bit string representing x
);
    
    // enc8(x): returns an 8-bit string representing x
    assign enc8_out = x;

endmodule
