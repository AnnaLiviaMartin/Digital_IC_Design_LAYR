`timescale 1ns/1ps

module kmac_top_cshake #(
    parameter int RATE_BITS = 1088,
    parameter int CAPACITY = 128
)(
    input  logic                  clk,
    input  logic                  rst_n,
    input  logic                  start,
    input  logic [CAPACITY-1:0]   key,
    input  logic [RATE_BITS-1:0]  msg_block,
    input  logic [15:0]           msg_bit_len,
    output logic [255:0]          mac_out,
    output logic                  mac_done
);

    typedef enum logic [4:0] {
        IDLE, KEY_BYTEPAD, ENCODE_STR, STR_BYTEPAD, LEFT_CONCAT,
        ABSORB_KEY_STR, MSG_BYTEPAD, ABSORB_MSG, RIGHT_PAD, SQUEEZE_MAC
    } state_t;
    
    state_t state, state_next;
    logic [RATE_BITS-1:0] cshake_in;
    
    // SEPARATE input/output arrays - KEIN Multiple Driver!
    logic [7:0] key_input [0:7], key_pad [0:7]; 
    logic [7:0] str_input [0:7], str_pad [0:7]; 
    logic [7:0] msg_input [0:7], msg_pad [0:7];
    logic [7:0] enc_bytes [0:7];
    
    logic key_done, enc_done, str_done, msg_done, right_done, kdone;
    logic key_start, enc_start, str_start, msg_start, right_start;
    
    // Key input unpack
    genvar gi;
    generate
        for(gi=0; gi<8; gi=gi+1)
            assign key_input[gi] = key[8*gi +: 8];
    endgenerate
    
    // "KMAC" string
    logic [7:0] kmac [0:7];
    assign kmac[0]=8'h4B; assign kmac[1]=8'h4D; assign kmac[2]=8'h41; assign kmac[3]=8'h43;
    generate for(gi=4; gi<8; gi=gi+1) assign kmac[gi]=8'h00; endgenerate
    
    // msg_block unpack
    generate
        for(gi=0; gi<8; gi=gi+1)
            assign msg_input[gi] = msg_block[8*gi +: 8];
    endgenerate
    
    // State register
    always_ff @(posedge clk or negedge rst_n)
        if(!rst_n) state <= IDLE; else state <= state_next;
    
    // State logic
    always @(*) begin
        state_next = state; mac_done = 0;
        key_start = 0; enc_start = 0; str_start = 0; msg_start = 0; right_start = 0;
        case(state)
            IDLE: if(start) state_next = KEY_BYTEPAD;
            KEY_BYTEPAD: if(key_done) state_next = ENCODE_STR;
            ENCODE_STR: if(enc_done) state_next = STR_BYTEPAD;
            STR_BYTEPAD: if(str_done) state_next = LEFT_CONCAT;
            LEFT_CONCAT: state_next = ABSORB_KEY_STR;
            ABSORB_KEY_STR: if(kdone) state_next = MSG_BYTEPAD;
            MSG_BYTEPAD: if(msg_done) state_next = ABSORB_MSG;
            ABSORB_MSG: if(kdone) state_next = RIGHT_PAD;
            RIGHT_PAD: if(right_done) state_next = SQUEEZE_MAC;
            SQUEEZE_MAC: begin mac_done = 1'b1; state_next = IDLE; end
        endcase
        
        if(state == KEY_BYTEPAD) key_start = 1'b1;
        if(state == ENCODE_STR) enc_start = 1'b1;
        if(state == STR_BYTEPAD) str_start = 1'b1;
        if(state == MSG_BYTEPAD) msg_start = 1'b1;
        if(state == RIGHT_PAD) right_start = 1'b1;
    end
    
    // Submodules - SEPARATE in/out arrays
    bytepad #(.W(8)) keypad (
        .clk(clk), .rst_n(rst_n), .start(key_start),
        .X_bytes(key_input), .L(3'd4),
        .pad_bytes(key_pad), .pad_done(key_done)
    );
    
    kmac_encode_string #(.MAX_LEN(8)) encstr (
        .clk(clk), .rst_n(rst_n), .start(enc_start),
        .str_bytes(kmac), .str_len(4'd4),
        .enc_bytes(enc_bytes), .enc_done(enc_done)
    );
    
    bytepad #(.W(8)) strpad (
        .clk(clk), .rst_n(rst_n), .start(str_start),
        .X_bytes(enc_bytes), .L(3'd4),
        .pad_bytes(str_pad), .pad_done(str_done)
    );
    
    bytepad #(.W(8)) msgpad (
        .clk(clk), .rst_n(rst_n), .start(msg_start),
        .X_bytes(msg_input), .L(3'd1),
        .pad_bytes(msg_pad), .pad_done(msg_done)
    );
    
    logic [63:0] right64;
    kmac_right_pad rightpad (
        .clk(clk), .rst_n(rst_n), .start(right_start),
        .bit_len(msg_bit_len),
        .enc8_0(enc_bytes[0]), .enc8_1(enc_bytes[1]),
        .enc8_2(enc_bytes[2]), .enc8_3(enc_bytes[3]),
        .right_pad_out(right64), .done(right_done)
    );
    
    logic kstart = (state==LEFT_CONCAT) || (state==ABSORB_MSG) || (state==RIGHT_PAD);
    Keccak #(.C_BITS(128), .X_BITS(RATE_BITS), .L_BITS(256)) keccak (
        .clk(clk), .rst_n(rst_n), .start(kstart),
        .c({128{1'b1}}), .X(cshake_in), .L(mac_out), .done(kdone)
    );
    
    // MUX mit Bit-Slicing (iverilog safe)
    always @(*) begin
        cshake_in = '0;
        if(state == RIGHT_PAD)
            cshake_in[RATE_BITS-1 -: 64] = right64;
        else if(state == LEFT_CONCAT) begin
            cshake_in[RATE_BITS-1 -: 8]  = key_pad[0];
            cshake_in[RATE_BITS-9  -: 8] = key_pad[1];
            cshake_in[RATE_BITS-17 -: 8] = key_pad[2];
            cshake_in[RATE_BITS-25 -: 8] = key_pad[3];
            cshake_in[RATE_BITS-33 -: 8] = str_pad[0];
            cshake_in[RATE_BITS-41 -: 8] = str_pad[1];
            cshake_in[RATE_BITS-49 -: 8] = str_pad[2];
            cshake_in[RATE_BITS-57 -: 8] = str_pad[3];
        end else if(state == ABSORB_MSG) begin
            cshake_in[RATE_BITS-1 -: 8]  = msg_pad[0];
            cshake_in[RATE_BITS-9  -: 8] = msg_pad[1];
            cshake_in[RATE_BITS-17 -: 8] = msg_pad[2];
            cshake_in[RATE_BITS-25 -: 8] = msg_pad[3];
            cshake_in[RATE_BITS-33 -: 8] = msg_pad[4];
            cshake_in[RATE_BITS-41 -: 8] = msg_pad[5];
            cshake_in[RATE_BITS-49 -: 8] = msg_pad[6];
            cshake_in[RATE_BITS-57 -: 8] = msg_pad[7];
        end
    end

endmodule
