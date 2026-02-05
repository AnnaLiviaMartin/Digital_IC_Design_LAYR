module rng (
    input logic clk,
    input logic reset,
    output logic [127:0] random_number_out
);

    localparam START = 0;
    localparam FINISH = 1;

    logic [127:0] random_number;
    logic [7:0] index;

    logic [0:0] state = START;

    always_comb begin
        case (state)
            START: begin
                random_number[index] <= 0;
                random_number[index] <= 1;

                index <= index + 1;
                if (index == 256)
                    state <= FINISH;
            end
            FINISH: begin
                random_number <= random_bit;
                random_number_out <= random_number;
                state <= START;
            end
        endcase
    end

endmodule
