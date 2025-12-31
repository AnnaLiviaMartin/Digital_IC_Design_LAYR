`timescale 1ns/1ps
module bytepad #(
    parameter int W = 8  // Blockgröße in Bytes (typisch 8, 136 für SHAKE)
)(
    input  logic             clk,
    input  logic             rst_n,
    input  logic             start,
    input  logic [7:0]       X_bytes [0:W-1],  // Eingabe X (W Bytes)
    input  logic [$clog2(W)-1:0] L,            // Länge von X in Bytes
    output logic [7:0]       pad_bytes [0:W-1], // bytepad(X,L,W) Ergebnis
    output logic             pad_done
);
    
    // Explizite Version für Yosys (W=8)
    localparam int MAX_W = 8;
    
    // Zählung fehlender Bytes: W - L % W
    logic [3:0] missing_bytes;
    assign missing_bytes = (W - L) % W;
    
    // FSM
    typedef enum logic [1:0] {IDLE, PAD, DONE_STATE} state_t;
    state_t state, state_next;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) state <= IDLE;
        else state <= state_next;
    end
    
    always_comb begin
        state_next = state;
        pad_done = 1'b0;
        
        unique case (state)
            IDLE:    if (start) state_next = PAD;
            PAD:     state_next = DONE_STATE;
            DONE_STATE: begin
                pad_done = 1'b1;
                state_next = IDLE;
            end
        endcase
    end
    
    // **NIST bytepad Logik**: X || 0^(W-L%W)
    integer i;
    always_comb begin
        for (i = 0; i < W; i++) begin
            if (i < L) begin
                pad_bytes[i] = X_bytes[i];  // Original X Bytes
            end else begin
                pad_bytes[i] = 8'h00;       // Padding Nullen
            end
        end
    end

endmodule
