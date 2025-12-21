module pad10_1 #(
    parameter int R_BITS = 11,
    parameter int M_BITS = 8,
    parameter int P_BITS = 256  // Ausgabebreite für 10^z (ca. 10^9999999 hat ~10M Stellen)
)(
    input  logic             clk,
    input  logic             rst_n,
    input  logic             start,
    input  logic [R_BITS-1:0] r,
    input  logic [M_BITS-1:0] m,
    output logic [P_BITS-1:0] P,
    output logic             done
);

    // Zustände für FSM
    localparam logic [2:0] IDLE         = 3'd0;
    localparam logic [2:0] SEARCH_Z     = 3'd1;  
    localparam logic [2:0] COMPUTE_POWER = 3'd2;
    localparam logic [2:0] FINISH       = 3'd3;

    logic [2:0] state, state_next;
    
    // Zähler für z-Suche (24 Bit reichen für 16M)
    logic [23:0] z_cnt;
    logic [23:0] z_cnt_next;
    
    // Temporäre Register
    logic [R_BITS-1:0] temp_sum;
    logic [R_BITS:0]   mod_result;  // +1 Bit für Überlauf
    
    // Power-Berechnung (Square-and-Multiply für 10^z mod irgendwas?)
    logic [P_BITS-1:0] base_reg, result_reg, square_reg;
    logic              power_busy;
    
    // Zähler-Inkrement und Modulo-Check
    assign temp_sum = z_cnt + m + 2;
    assign mod_result = temp_sum % r;
    
    // FSM: State Register
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            z_cnt <= 24'd0;
        end else begin
            state <= state_next;
            z_cnt <= z_cnt_next;
        end
    end
    
    // FSM: Next State + Output Logic
    always_comb begin
        state_next = state;
        z_cnt_next = z_cnt;
        done = 1'b0;
        
        unique case (state)
            IDLE: begin
                if (start) begin
                    state_next = SEARCH_Z;
                    z_cnt_next = 24'd0;
                    P = {{P_BITS}{1'b0}}
                end
            end
            
            SEARCH_Z: begin
                if (mod_result == 0) begin  // (z + m + 2) mod r == 0 gefunden!
                    state_next = COMPUTE_POWER;
                end else begin
                    z_cnt_next = z_cnt + 1;
                    if (z_cnt == 24'd9999999) begin
                        state_next = FINISH;  // Timeout
                    end
                end
            end
            
            COMPUTE_POWER: begin
                P = (1'b1 << z_cnt) | 1'b1;
                state_next = FINISH;
            end
            
            FINISH: begin
                done = 1'b1;
                state_next = IDLE;
            end
            
            default: state_next = IDLE;
        endcase
    end

endmodule


