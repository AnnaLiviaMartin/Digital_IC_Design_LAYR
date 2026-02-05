module ascon (
    input logic clk,
    input logic [127:0] data_in,
    output logic [319:0] hash_out
);

    localparam START = 0;
    localparam PERM_A = 1;
    localparam PERM_B = 2;
    localparam PERM_C = 3;
    localparam FINISH = 4;

    localparam round_constants = 96'h_f1_e1_d2_c3_b4_a5_96_87_78_69_5a_4b;
    localparam round_limit = 12;

    logic [255:0] IV;
    logic [319:0] S;
    logic [2:0] state = START;

    logic [3:0] round_index;
    logic [3:0] round_constants_index;

    logic [63:0] x0;
    logic [63:0] x1;
    logic [63:0] x2;
    logic [63:0] x3;
    logic [63:0] x4;

    logic [63:0] t0;
    logic [63:0] t1;
    logic [63:0] t2;
    logic [63:0] t3;
    logic [63:0] t4;

    always_ff @(posedge clk) begin
        case (state)
            START: begin
                // IV <= 256'0;
                // S <= {64'0, IV};
                S <= 320'h_ee9398aadb67f03d_8bb21831c60f1002_b48a92db98d5da62_43189921b8f8e3e8_348fa5c9d525e140;
                round_index <= 0;
                x0 <= S[63:0];
                x1 <= S[127:64];
                x2 <= S[191:128];
                x3 <= S[255:192];
                x4 <= S[319:256];

                state <= PERM_A;
            end
            PERM_A: begin
                round_constants_index <= 96 - round_index * 8 - 1;
                x2 <= x2 ^ round_constants[round_constants_index : round_constants_index - 7];
                state <= PERM_B;
            end
            PERM_B: begin
                x0 <= x0 ^ x4;
                x4 <= x4 ^ x3;
                x2 <= x2 ^ x1;

                t0 <= ~x0;
                t1 <= ~x1;
                t2 <= ~x2;
                t3 <= ~x3;
                t4 <= ~x4;

                t0 <= t0 & x1;
                t1 <= t1 & x2;
                t2 <= t2 & x3;
                t3 <= t3 & x4;
                t4 <= t4 & x0;

                x0 <= x0 ^ t1;
                x1 <= x1 ^ t2;
                x2 <= x2 ^ t3;
                x3 <= x3 ^ t4;
                x4 <= x4 ^ t0;

                x1 <= x1 ^ x0;
                x0 <= x0 ^ x4;
                x3 <= x3 ^ x2;
                x2 <= ~x2;

                state <= PERM_C;
            end
            PERM_C: begin
                x0 <= x0 ^ ((x0 >> 19) ^ (x0 >> 28));
                x1 <= x1 ^ ((x1 >> 61) ^ (x1 >> 39));
                x2 <= x2 ^ ((x2 >> 1) ^ (x2 >> 6));
                x3 <= x3 ^ ((x3 >> 10) ^ (x3 >> 17));
                x4 <= x4 ^ ((x4 >> 7) ^ (x4 >> 41));

                round_index <= round_index + 1;
                state <= (round_index == round_limit) ? FINISH : PERM_A;
            end
            FINISH: begin
                S <= {x0, x1, x2, x3, x4};
                hash_out <= S;
                state <= START;
            end
        endcase
    end

endmodule
