`timescale 1ns/1ps

module kmac_ascon_top #(
    parameter int RATE_BITS = 1088,
    parameter int CAPACITY = 128
)(
    input  logic             clk,
    input  logic             rst_n,
    
    // KMAC Eingaben
    input  logic             kmac_start,
    input  logic [CAPACITY-1:0] key,
    input  logic [RATE_BITS-1:0] msg_block,
    input  logic [15:0]      msg_bit_len,
    
    // Ascon Hash Eingaben  
    input  logic             hash_start,
    input  logic [63:0]      hash_msg_in,
    input  logic             hash_msg_last,
    
    // Gemeinsame Ausgaben
    output logic [255:0]     kmac_out,
    output logic             kmac_done,
    output logic [255:0]     hash_out,
    output logic             hash_ready,
    
    // Status (Debug)
    output logic [2:0]       top_state
);

    // ========================================
    // TOP LEVEL STATE MACHINE - KOMPLETT FIX
    // ========================================
    typedef enum logic [1:0] {
        IDLE_TOP   = 2'b00,
        KMAC_MODE  = 2'b01,
        ASCON_MODE = 2'b10
    } top_state_t;
    
    top_state_t current_top_state, next_top_state;
    logic [63:0] ascon_msg;
    logic ascon_msg_start, ascon_msg_last;
    logic kmac_mac_out_valid;
    
    // State Register
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            current_top_state <= IDLE_TOP;
        else 
            current_top_state <= next_top_state;
    end
    
    // State Kombinatorik - JETZT FUNKTIONIERT!
    always_comb begin
        next_top_state = current_top_state;
        unique case (current_top_state)
            IDLE_TOP: begin
                if (kmac_start)      next_top_state = KMAC_MODE;
                else if (hash_start) next_top_state = ASCON_MODE;
            end
            KMAC_MODE:   if (kmac_done)   next_top_state = IDLE_TOP;
            ASCON_MODE: begin
                if (kmac_start)      next_top_state = KMAC_MODE;  
                else if (hash_ready) next_top_state = IDLE_TOP;
            end

            default:     next_top_state = IDLE_TOP;
        endcase
    end
    
    assign top_state = current_top_state;

    // ========================================
    // KMAC INSTANZ - MAC_DONE WIEDER EINFÜGEN
    // ========================================
    wire kmac_internal_done;
    kmac_top_cshake #(.RATE_BITS(RATE_BITS), .CAPACITY(CAPACITY)) kmac_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(kmac_start),
        .key(key),
        .msg_block(msg_block),
        .msg_bit_len(msg_bit_len),
        .mac_out(kmac_out),
        .mac_done(kmac_internal_done)
    );
    assign kmac_done = kmac_internal_done;  

    // ========================================
    // ASCON INSTANZ
    // ========================================
    ascon_statmachine_top ascon_inst (
        .clk(clk),
        .rst_n(rst_n),
        .msg_in(ascon_msg),
        .msg_start(ascon_msg_start),
        .msg_last(ascon_msg_last),
        .hash_out(hash_out),
        .hash_ready(hash_ready)
    );
    
    // ========================================
    // KMAC → ASCON DATAPATH
    // ========================================
    assign kmac_mac_out_valid = kmac_done;
    always_ff @(posedge clk) begin
        ascon_msg_start <= 1'b0;
        ascon_msg_last  <= 1'b0;
        if (kmac_mac_out_valid) begin
            ascon_msg      <= kmac_out[63:0];
            ascon_msg_start <= 1'b1;
            ascon_msg_last  <= 1'b1;
        end
    end

endmodule
