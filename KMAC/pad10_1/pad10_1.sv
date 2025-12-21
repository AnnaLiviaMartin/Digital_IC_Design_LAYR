`timescale 1ns / 1ps
module pad10_1 #(
    parameter int R_BITS = 11,
    parameter int M_BITS = 8,
    parameter int P_BITS = 256
)(
    input  logic             clk,
    input  logic             rst_n,
    input  logic             start,
    input  logic [R_BITS-1:0] r,
    input  logic [M_BITS-1:0] m,
    output logic [P_BITS-1:0] P,
    output logic             done
);

    // Zustände für FSM (Yosys/iCE40-kompatibel)
    localparam logic [2:0] IDLE         = 3'd0;
    localparam logic [2:0] SEARCH_Z     = 3'd1;  
    localparam logic [2:0] COMPUTE_POWER = 3'd2;
    localparam logic [2:0] FINISH       = 3'd3;

    logic [2:0] state, state_next;
    
    // Zähler für z-Suche (24 Bit reichen für 16M)
    logic [23:0] z_cnt;
    
    // Temporäre Register
    logic [R_BITS:0] temp_sum;  // +1 Bit Überlauf
    logic [R_BITS:0] mod_result;
    
    // Zähler-Inkrement und Modulo-Check
    assign temp_sum = z_cnt[23:R_BITS] + m + 2;  // Upper bits von z_cnt
    assign mod_result = temp_sum % r;
    
    // FSM: State Register
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            z_cnt <= 24'd0;
        end else begin
            state <= state_next;
        end
    end
    
    always_comb begin
        state_next = state;
        done = 1'b0;
        P = '0;
        
        unique case (state)
            IDLE: begin
                if (start) begin
                    state_next = SEARCH_Z;
                end
            end
            
            SEARCH_Z: begin
                
                if ((z_cnt[R_BITS-1:0] + m + 2) % r == 0) begin  // ALTES z_cnt checken!
                    state_next = COMPUTE_POWER;
                end else if (z_cnt == 24'd9999999) begin
                    state_next = FINISH;
                end
                z_cnt = z_cnt + 1;  // IMMER inkrementieren!
            end
            
            COMPUTE_POWER: begin
                //P = (1'b1 << z_cnt[7:0]) | 1'b1;  // 1 z*0 1 (8-bit z_cnt)
                P = (1'b1 << (z_cnt[7:0] + 2)) | 1'b1;
                state_next = FINISH;
            end
            
            FINISH: begin
                done = 1'b1;
                state_next = IDLE;
            end
            
            default: begin
                state_next = IDLE;
            end
        endcase
    end

endmodule