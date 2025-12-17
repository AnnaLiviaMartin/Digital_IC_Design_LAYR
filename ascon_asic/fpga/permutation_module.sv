module ascon_permutation (
    input logic clk,
    input logic permutation_start,
    input logic [319:0] state_in,
    output logic [319:0] state_out,
    output logic permutation_done
);

function [63:0] round_constant;
    input integer index;
    begin
        case (index)
            0: round_constant = 64'h000000000000003c;
            1: round_constant = 64'h000000000000002d;
            2: round_constant = 64'h000000000000001e;
            3: round_constant = 64'h000000000000000f;
            4: round_constant = 64'h00000000000000f0;
            5: round_constant = 64'h00000000000000e1;
            6: round_constant = 64'h00000000000000d2;
            7: round_constant = 64'h00000000000000c3;
            8: round_constant = 64'h00000000000000b4;
            9: round_constant = 64'h00000000000000a5;
            10: round_constant = 64'h0000000000000096;
            11: round_constant = 64'h0000000000000087;
            default: round_constant = 64'h0000000000000000;
        endcase
    end
endfunction

function [63:0] rot;
    input [63:0] x;    // Input data to be rotated
    input [5:0] n;     // Number of positions to rotate
    begin
        rot = (x >> n) | (x << (64 - n));  // Perform the rotation
    end
endfunction

logic [3:0] round;


logic [63:0] s0, s1, s2, s3, s4; // state_in aufteilen s0 bis s4 s. specs
logic [63:0] s0_next, s1_next, s2_next, s3_next, s4_next; // neues wort von state_in
logic [63:0] T[4:0];

always @(posedge clk) begin
    if (permutation_start && !permutation_done) begin

        s2 = s2 ^ round_constant(round);

        s0_next = s0 ^ s4;
        s4_next = s4 ^ s3;
        s2_next = s2 ^ s1;

        T[0] = (s0_next ^ 64'hFFFFFFFFFFFFFFFF) & s1;
        T[1] = (s1 ^ 64'hFFFFFFFFFFFFFFFF) & s2_next;
        T[2] = (s2_next ^ 64'hFFFFFFFFFFFFFFFF) & s3;
        T[3] = (s3 ^ 64'hFFFFFFFFFFFFFFFF) & s4_next;
        T[4] = (s4_next ^ 64'hFFFFFFFFFFFFFFFF) & s0_next;
        s0_next = s0_next ^ T[1];
        s1_next = s1 ^ T[2];
        s2_next = s2_next ^ T[3];
        s3_next = s3 ^ T[4];
        s4_next = s4_next ^ T[0];
        s1_next = s1_next ^ s0_next;
        s0_next = s0_next ^ s4_next;
        s3_next = s3_next ^ s2_next;
        s2_next = s2_next ^ 64'hFFFFFFFFFFFFFFFF;

        s0_next = s0_next ^ rot(s0_next, 19) ^ rot(s0_next, 28);
        s1_next = s1_next ^ rot(s1_next, 61) ^ rot(s1_next, 39);
        s2_next = s2_next ^ rot(s2_next, 1) ^ rot(s2_next, 6);
        s3_next = s3_next ^ rot(s3_next, 10) ^ rot(s3_next, 17);
        s4_next = s4_next ^ rot(s4_next, 7) ^ rot(s4_next, 41);

        s0 = s0_next;
        s1 = s1_next;
        s2 = s2_next;
        s3 = s3_next;
        s4 = s4_next;

        if (round == 11) begin
            state_out = {s0_next, s1_next, s2_next, s3_next, s4_next};
            permutation_done <= 1;
        end else begin
            round <= round + 1;
        end
    end else if (!permutation_start) begin
        round <= 0;
        permutation_done <= 0;
        state_out <= 0;
        s0 <= state_in[319:256];
        s1 <= state_in[255:192];
        s2 <= state_in[191:128];
        s3 <= state_in[127:64];
        s4 <= state_in[63:0];
    end
end

endmodule
