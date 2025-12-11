module Counter #(
    parameter integer WIDTH = 29
)(
    input logic         clk,
    input logic         reset,
    output logic [3:0]   gleds,
    output logic         rled     
);
    logic [WIDTH-1:0] val;

    always_ff@(posedge clk) begin
        if(reset) begin
            val <= {WIDTH{1'b0}};
        end else begin
            val++;
        end
    end

    always_comb begin
        gleds <= val [WIDTH-1 : WIDTH-4];
        rled <= reset;
    end

endmodule
