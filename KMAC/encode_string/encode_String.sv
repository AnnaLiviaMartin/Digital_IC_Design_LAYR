`timescale 1ns/1ps
module kmac_encode_string #(
    parameter int MAX_LEN = 32  // Maximale Stringlänge
)(
    input  logic             clk,
    input  logic             rst_n,
    input  logic             start,
    input  logic [7:0]       str_bytes [0:MAX_LEN-1],  // String S als Bytes
    input  logic [$clog2(MAX_LEN+1)-1:0] str_len,     // Länge L ∈ [0,MAX_LEN]
    output logic [7:0]       enc_bytes [0:MAX_LEN-1],  // enc8(0)||enc8(1)||...||enc8(L-1)
    output logic             enc_done
);
    
    // enc8 Instanzen (generate)
    genvar i;
    generate
        for (i = 0; i < MAX_LEN; i++) begin : enc8_array
            enc8_kmac enc (
                .x(i[7:0]),
                .enc8_out(enc_bytes[i])
            );
        end
    endgenerate
    
    // FSM
    typedef enum logic [1:0] {IDLE, ENCODE, DONE_STATE} state_t;
    state_t state, state_next;
    
    // State Register
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) state <= IDLE;
        else state <= state_next;
    end
    
    // Next State Logic
    always_comb begin
        state_next = state;
        enc_done = 1'b0;
        
        unique case (state)
            IDLE:    if (start) state_next = ENCODE;
            ENCODE:  state_next = DONE_STATE;
            DONE_STATE: begin
                enc_done = 1'b1;
                state_next = IDLE;
            end
            default: state_next = IDLE;
        endcase
    end

endmodule
