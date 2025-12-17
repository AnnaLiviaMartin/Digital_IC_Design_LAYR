module ascon_hmac_top #(
    parameter KEY_BITS   = 64,
    parameter HASH_BITS  = 256
)(
    input  logic                 clk,
    input  logic                 rst_n,

    // HMAC Interface
    input  logic                 hmac_start,
    input  logic [KEY_BITS-1:0]  key_in,
    input  logic [63:0]          msg_in,
    input  logic                 msg_valid,
    input  logic                 msg_last,

    output logic [HASH_BITS-1:0] hmac_out,
    output logic                 hmac_ready
);

    // hmac states
    localparam [2:0] INIT                      = 3'b000;
    localparam [2:0] CREATE_INNER_INPUT        = 3'b001;
    localparam [2:0] CONCAT_INNER_INPUT        = 3'b010;
    localparam [2:0] PRODUCE_INNER_ASCON       = 3'b011;
    localparam [2:0] CREATE_OUTER_INPUT        = 3'b100;
    localparam [2:0] CONCAT_OUTER_INNER_ASCON  = 3'b101;
    localparam [2:0] PRODUCE_OUTER_ASCON       = 3'b110;
    localparam [2:0] FINISH                    = 3'b111;

    reg [2:0] hmac_state;
    reg [2:0] hmac_state_next;

    // ipad/opad
    localparam [63:0] IPAD_BLOCK = 64'h36363636_36363636;
    localparam [63:0] OPAD_BLOCK = 64'h5c5c5c5c_5c5c5c5c;

    // connection to ascon-hash
    reg         ascon_start;
    reg         ascon_last;
    reg  [63:0] ascon_msg_in;
    wire [HASH_BITS-1:0] ascon_hash_out;
    wire        ascon_hash_ready;

    // instance of ascon hash module
    ascon_statmachine_top ascon (
        .clk        (clk),
        .rst_n      (rst_n),
        .msg_in     (ascon_msg_in),
        .msg_start  (ascon_start),
        .msg_last   (ascon_last),
        .hash_out   (ascon_hash_out),
        .hash_ready (ascon_hash_ready)
    );

    //-----------------------------
    // Zustandsregister
    //-----------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            hmac_state <= INIT;
        else
            hmac_state <= hmac_state_next;
    end

    //-----------------------------
    // HMAC‑FSM Kombilogik
    //-----------------------------
    always @(posedge clk) begin
        case (hmac_state)
            INIT: begin
                if (hmac_start)
                    hmac_state_next = CREATE_INNER_INPUT;
            end

            CREATE_INNER_INPUT: begin
                // (K xor ipad) als erster Block
                ascon_start     = 1'b1;     // Pulse
                hmac_state_next = CONCAT_INNER_INPUT;
            end

            CONCAT_INNER_INPUT: begin
                // Nutzdaten anhängen, bis msg_last
                if (msg_valid_reg && msg_last_reg) begin
                    ascon_last      = 1'b1;
                    hmac_state_next = PRODUCE_INNER_ASCON;
                end
            end

            PRODUCE_INNER_ASCON: begin
                if (ascon_hash_ready)
                    hmac_state_next = CREATE_OUTER_INPUT;
            end

            CREATE_OUTER_INPUT: begin
                // (K xor opad) als erster Block
                ascon_start     = 1'b1;
                hmac_state_next = CONCAT_OUTER_INNER_ASCON;
            end

            CONCAT_OUTER_INNER_ASCON: begin
                // 4×64‑Bit‑Wörter von inner_hash ausgeben
                if (inner_word_cnt == 2'd3) begin
                    ascon_last      = 1'b1;
                    hmac_state_next = PRODUCE_OUTER_ASCON;
                end
            end

            PRODUCE_OUTER_ASCON: begin
                if (ascon_hash_ready)
                    hmac_state_next = FINISH;
            end

            FINISH: begin
                hmac_ready = 1'b1;
                if (!hmac_start)
                    hmac_state_next = INIT;
            end

            default: hmac_state_next = INIT;
        endcase
    end

endmodule
