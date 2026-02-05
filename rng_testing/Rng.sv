module rng ( //count to 2^WIDTH
    input logic clk,
    input logic a,
    input logic b,
    output logic bit_out
);

    logic c = 0;

    always_ff @(posedge clk) begin
        c <= ~c;
    end

    always_comb begin
        bit_out <= c;
        // bit_out <= val % 2;
    end

endmodule

/*
module rng (
    input logic clk,
    input logic a,
    input logic b,
    output logic bit_out
);



    always @ (posedge clk) begin
        x1 <= a;
        x2 <= b;
    end

    //always @ (posedge clk) begin
    //    x1 <= a;
    //    x2 <= b;
    //end

    always @ (posedge clk) begin
        //bit_out <= x1 | x2;
        bit_out <= x1 & x2;
    end
endmodule
*/

/*
module rng (
    input logic clk,
    output logic [0:0] bit_out
);

always_comb begin
    bit_out <= ~bit_out;
end

endmodule
*/