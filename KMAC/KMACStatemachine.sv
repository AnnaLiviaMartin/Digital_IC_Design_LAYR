module kmac_top_cshake #(
    parameter int RATE_BITS = 1088,  // cSHAKE128: r=1088
    parameter int KEY_BITS   = 128,
    parameter int STR_LEN    = 15     // "KMACKMAC" customization
)(
    input  logic                  clk,
    input  logic                  rst_n,
    input  logic                  start,
    input  logic [KEY_BITS-1:0]   key,           // KMAC Key
    input  logic [RATE_BITS-1:0]  msg_block,     // Message Block
    input  logic [15:0]           msg_bit_len,   // Message bit length
    output logic [255:0]          mac_out,       // 256-bit KMAC output
    output logic                  mac_done
);

    // **NIST KMAC Pipeline Stages**
    typedef enum logic [4:0] {
        IDLE,
        KEY_BYTEPAD,           // bytepad(key, |key|, r/8)
        ENCODE_STR,            // encode_string("KMACKMAC", 15)
        STR_BYTEPAD,           // bytepad(encode_string, 8, r/8)
        LEFT_CONCAT,           // bytepad(key)||bytepad(str)
        ABSORB_KEY_STR,        // cSHAKE Absorb
        MSG_BYTEPAD,           // bytepad(msg, |msg|, r/8)
        ABSORB_MSG,            // cSHAKE Absorb msg
        RIGHT_PAD,             // right-pad(|msg|)
        SQUEEZE_MAC            // cSHAKE Squeeze 256 bits
    } kmac_state_t;
    
    kmac_state_t state, state_next;
    
    // **Submodule Interfaces**
    logic [7:0] key_padded [0:135];      // bytepad(key)
    logic [7:0] enc_str [0:7];           // encode_string("KMACKMAC")
    logic [7:0] str_padded [0:7];        // bytepad(enc_str)
    logic [7:0] msg_padded [0:135];      // bytepad(msg)
    logic [7:0] enc8_right [0:3];        // right-pad enc8
    logic [RATE_BITS-1:0] cshake_in;     // cSHAKE Input
    logic                  cshake_done;
    
    // **State Register**
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
        end else begin
            state <= state_next;
        end
    end
    
    // **Next State + Control Logic**
    always_comb begin
        state_next = state;
        mac_done = 1'b0;
        
        unique case (state)
            IDLE:           if (start) state_next = KEY_BYTEPAD;
            KEY_BYTEPAD:    state_next = ENCODE_STR;
            ENCODE_STR:     state_next = STR_BYTEPAD;
            STR_BYTEPAD:    state_next = LEFT_CONCAT;
            LEFT_CONCAT:    state_next = ABSORB_KEY_STR;
            ABSORB_KEY_STR: state_next = MSG_BYTEPAD;
            MSG_BYTEPAD:    state_next = ABSORB_MSG;
            ABSORB_MSG:     state_next = RIGHT_PAD;
            RIGHT_PAD:      state_next = SQUEEZE_MAC;
            SQUEEZE_MAC: begin
                mac_done = 1'b1;
                state_next = IDLE;
            end
            default:        state_next = IDLE;
        endcase
    end
    
    // **1. key_bytepad**
    kmac_bytepad #(128) key_pad (
        .clk(clk), .rst_n(rst_n), .start(state == KEY_BYTEPAD),
        .L(key_bits/8), .X_bytes(key_bytes),
        .pad_bytes(key_padded), .pad_done()
    );
    
    // **2. encode_string("KMACKMAC")**
    kmac_encode_string #(8) enc_str_inst (
        .clk(clk), .rst_n(rst_n), .start(state == ENCODE_STR),
        .str_len(8'd8),
        .enc0(enc8_right[0]), .enc1(enc8_right[1]),
        .enc2(enc8_right[2]), .enc3(enc8_right[3]),
        .enc_done()
    );
    
    // **3. str_bytepad**
    kmac_bytepad #(64) str_pad (
        .clk(clk), .rst_n(rst_n), .start(state == STR_BYTEPAD),
        .L(8'd8), .X_bytes(enc_str),
        .pad_bytes(str_padded), .pad_done()
    );
    
    // **4. msg_bytepad**
    kmac_bytepad #(128) msg_pad (
        .clk(clk), .rst_n(rst_n), .start(state == MSG_BYTEPAD),
        .L(msg_bit_len/8), .X_bytes(msg_bytes),
        .pad_bytes(msg_padded), .pad_done()
    );
    
    // **5. right_pad**
    kmac_right_pad right_pad_inst (
        .clk(clk), .rst_n(rst_n), .start(state == RIGHT_PAD),
        .bit_len(msg_bit_len),
        .enc8_0(enc8_right[0]), .enc8_1(enc8_right[1]),
        .enc8_2(enc8_right[2]), .enc8_3(enc8_right[3]),
        .right_pad_out(right_pad_data), .done()
    );
    
    // **6. cSHAKE Core (vereinfacht)**
    cshake_core #(
        .RATE_BITS(RATE_BITS)
    ) cshake_inst (
        .clk(clk), .rst_n(rst_n),
        .absorb(state == ABSORB_KEY_STR || state == ABSORB_MSG),
        .squeeze(state == SQUEEZE_MAC),
        .in_data(cshake_in),
        .out_data(mac_out),
        .done(cshake_done)
    );
    
    // **Data Multiplexing**
    always_comb begin
        case (state)
            LEFT_CONCAT:  cshake_in = {key_padded, str_padded};
            ABSORB_MSG:   cshake_in = msg_padded;
            RIGHT_PAD:    cshake_in = right_pad_data;
            default:      cshake_in = 0;
        endcase
    end

endmodule
