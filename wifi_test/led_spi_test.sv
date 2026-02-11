module ButtonLED (
    input  logic clk,
    input  logic reset,
    input  logic button,
    output logic led
);

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            led <= 1'b0;
        end else begin
            led <= button;
        end
    end

endmodule
