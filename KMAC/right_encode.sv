module kmac_right_pad (
    input  logic             clk,
    input  logic             rst_n,
    input  logic             start,
    input  logic [15:0]      bit_len,           // bitlen ∈ [0,2^16)
    input  logic [7:0]       enc8_0, enc8_1, enc8_2, enc8_3,
    output logic [63:0]      right_pad_out,
    output logic             done
);
    
    // NIST KMAC: M || 1 || 0^(bit_len+1) || enc8_seq
    localparam int MAX_ZEROS = 17;  // Max bit_len+1 = 65537 bits
    
    // FSM States
    typedef enum logic [1:0] {IDLE, COMPUTE, DONE_STATE} state_t;
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
        state_next = state;
        done = 1'b0;
        
        unique case (state)
            IDLE: begin
                if (start) begin
                    state_next = COMPUTE;
                end
            end
            
            COMPUTE: begin
                state_next = DONE_STATE;
            end
            
            DONE_STATE: begin
                done = 1'b1;
                state_next = IDLE;
            end
            
            default: state_next = IDLE;
        endcase
    end
    
    // **NIST KMAC right-pad Logik** (Yosys-kompatibel)
    logic [63:0] pad_data;
    logic [15:0] zero_count;
    
    assign zero_count = bit_len + 1;
    
    always_comb begin
        pad_data = 64'b0;
        
        // 1. "1" Bit an Position bit_len (nach M)
        if (bit_len < 64) begin
            pad_data[bit_len] = 1'b1;
        end
        
        // 2. 0^(bit_len+1) Nullen (Bits 0 bis bit_len)
        if (bit_len < 64) begin
            for (int i = 0; i <= bit_len; i++) begin
                pad_data[i] = 1'b0;
            end
        end
        
        // 3. enc8-Sequence (fixe Positionen nach Nullen)
        pad_data[39:32] = enc8_0;   // enc8(0)
        pad_data[47:40] = enc8_1;   // enc8(1)  
        pad_data[55:48] = enc8_2;   // enc8(2)
        pad_data[63:56] = enc8_3;   // enc8(3)
    end
    
    assign right_pad_out = pad_data;

endmodule
