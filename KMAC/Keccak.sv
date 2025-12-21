module Keccak #(
    parameter int C_BITS = 8,    // Kapazität Bits
    parameter int X_BITS = 8,    // Nachrichteneingabe Bits
    parameter int L_BITS = 256   // Ausgabe Bits (State)
)(
    input  logic             clk,
    input  logic             rst_n,
    input  logic             start,
    input  logic [C_BITS-1:0] c,     // Kapazität
    input  logic [X_BITS-1:0] X,     // Eingabe
    output logic [L_BITS-1:0] L,     // Ausgabe: x || tmp
    output logic             done
);

    // pad10_1 Instanz
    logic pad_start, pad_done;
    logic [8:0]        pad_r, pad_m;  // 9 Bit für pad10_1
    logic [L_BITS-1:0] pad_P;
    logic [23:0]       pad_z;
    
    pad10_1 #(
        .R_BITS(9),
        .M_BITS(9),
        .P_BITS(L_BITS)
    ) pad_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(pad_start),
        .r(pad_r),
        .m(pad_m),
        .P(pad_P),
        .z_out(pad_z),
        .done(pad_done)
    );
    
    // "x" als Konstante (z.B. 1 Bit gesetzt, anpassbar)
    localparam logic [L_BITS-1:0] X_CONST = 1'b1 << (L_BITS-1);  // MSB = 1
    
    // FSM States
    typedef enum logic [1:0] {
        IDLE,
        COMPUTE_PAD,
        CONCAT,
        DONE_STATE
    } state_t;
    
    state_t state, state_next;
    
    // State Register
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
        end else begin
            state <= state_next;
        end
    end
    
    // Next State + Output Logic
    always_comb begin
        // Defaults
        state_next = state;
        pad_start  = 1'b0;
        done       = 1'b0;
        L          = '0;
        pad_r      = 9'd1600 - c;  // 1600 - c für pad10_1
        pad_m      = X;            // X als m
        
        unique case (state)
            IDLE: begin
                if (start) begin
                    state_next = COMPUTE_PAD;
                end
            end
            
            COMPUTE_PAD: begin
                pad_start = 1'b1;
                if (pad_done) begin
                    state_next = CONCAT;
                end
            end
            
            CONCAT: begin
                // L = x || tmp  (X_CONST concat pad_P)
                L = {X_CONST, pad_P[L_BITS-2:0]};
                state_next = DONE_STATE;
            end
            
            DONE_STATE: begin
                done = 1'b1;
                state_next = IDLE;
            end
            
            default: state_next = IDLE;
        endcase
    end

endmodule
