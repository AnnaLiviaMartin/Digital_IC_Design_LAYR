module ascon_permutation #(
    parameter integer ROUNDS = 12   // ASCON-128a = 8, ASCON-128 = 12, etc.
)(
    input  logic         clk,
    input  logic         start,
    input  logic [319:0] state_in,
    output logic [319:0] state_out,
    output logic         done
);

    // Internal state: 5 × 64-bit
    logic [63:0] x0, x1, x2, x3, x4;

    // Round counter
    logic [$clog2(ROUNDS):0] round;
    logic running;

    // === ASCON Round Constants ===
    // (taken directly from the ASCON specification)
    function automatic logic [7:0] rc(input int r);
        rc = 8'hF0 ^ (8'(ROUNDS - r) << 4) ^ (8'(ROUNDS - r));
    endfunction

    // === S-Box (5-bit to 5-bit) ===
    function automatic logic [4:0] sbox(input logic [4:0] x);
        logic [4:0] y;
        logic [4:0] t;

        t = x ^ {x[3:0], x[4]};     // rotate-left to align bits
        y[0] = x[0] ^ (~x[1] & x[2]);
        y[1] = x[1] ^ (~x[2] & x[3]);
        y[2] = x[2] ^ (~x[3] & x[4]);
        y[3] = x[3] ^ (~x[4] & x[0]);
        y[4] = x[4] ^ (~x[0] & x[1]);
        y = y ^ (t >> 1);           // nonlinear tweak from spec
        return y;
    endfunction

    // === Apply S-box word-wise to 64-bit ===
    function automatic logic [63:0] sbox64(input logic [63:0] w);
        logic [63:0] out;
        for (int i = 0; i < 64; i += 5)
            out[i +: 5] = sbox(w[i +: 5]);
        return out;
    endfunction

    // === Linear Diffusion Layer ===
    function automatic logic [63:0] L(input logic [63:0] w);
        return w
            ^ {w[18:0], w[63:19]}   // ROTR 19
            ^ {w[27:0], w[63:28]}; // ROTR 28
    endfunction

    // === Whole Round ===
    task automatic round_f(input int r);
        logic [63:0] t0, t1, t2, t3, t4;

        // Add round constant
        x2 ^= {56'b0, rc(r)};

        // Substitution layer
        t0 = x0;
        t1 = x1;
        t2 = x2;
        t3 = x3;
        t4 = x4;

        x0 = t0 ^ t4 ^ (t1 & t2);
        x1 = t1 ^ t0 ^ (t2 & t3);
        x2 = t2 ^ t1 ^ (t3 & t4);
        x3 = t3 ^ t2 ^ (t4 & t0);
        x4 = t4 ^ t3 ^ (t0 & t1);

        x1 ^= x0;
        x3 ^= x2;
        x0 ^= x4;
        x2 ^= x1;
        x4 ^= x3;

        // Diffusion
        x0 = L(x0);
        x1 = L(x1);
        x2 = L(x2);
        x3 = L(x3);
        x4 = L(x4);
    endtask

    // === Control Logic ===
    always_ff @(posedge clk) begin
        if (start) begin
            {x0, x1, x2, x3, x4} <= state_in;
            round  <= 0;
            running <= 1;
            done <= 0;
        end else if (running) begin
            round <= round + 1;
            round_f(round);

            if (round == (ROUNDS - 1)) begin
                running <= 0;
                done <= 1;
                state_out <= {x0, x1, x2, x3, x4};
            end
        end 
    end

endmodule