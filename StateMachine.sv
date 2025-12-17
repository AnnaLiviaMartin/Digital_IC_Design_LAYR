module ascon_hmac_top #(
    parameter KEY_BITS   = 64,
    parameter HASH_BITS  = 256
)(
    input  logic                 clk,
    input  logic                 reset,

    // HMAC Interface
    input  logic                 hmac_start,//start des Algos
    input  logic [KEY_BITS-1:0]  key_in,    //key für berechnung
    input  logic [63:0]          msg_in,    //message die gegeben wird

    output logic [HASH_BITS-1:0] hmac_out, //ergebnishash
    output logic                 hmac_ready//flag ab wann fertig
);

    // hmac states
    localparam [2:0] INIT                      = 3'b000;
    localparam [2:0] CONCAT_INNER_INPUT        = 3'b001;
    localparam [2:0] PRODUCE_INNER_ASCON       = 3'b010;
    localparam [2:0] CONCAT_OUTER_INNER_ASCON  = 3'b011;
    localparam [2:0] PRODUCE_OUTER_ASCON       = 3'b100;
    localparam [2:0] FINISH                    = 3'b101;

    reg [2:0] hmac_state;
    reg [2:0] hmac_state_next;
    
    // ipad/opad
    localparam [63:0] IPAD_BLOCK = {8{8'h36}};
    localparam [63:0] OPAD_BLOCK = {8{8'h5c}};

    reg [63:0] inner_input;//Ipad xor
    reg [63:0] outer_input;// Opad xor

    reg [127:0] concat_inner;
    reg [319:0] concat_outer;
    

    // connection to ascon-hash
    reg                 ascon_start;
    reg                 ascon_last;
    reg  [63:0]         ascon_msg_in;
    wire [HASH_BITS-1:0] ascon_hash_out;
    wire                ascon_hash_ready;

    // instance of ascon hash module
    ascon_statmachine_top ascon (
        .clk        (clk),
        .rst_n      (reset),
        .msg_in     (ascon_msg_in),
        .msg_start  (ascon_start),
        .msg_last   (ascon_last),
        .hash_out   (ascon_hash_out),
        .hash_ready (ascon_hash_ready)
    );


    // instance of Xor
    xor xor_ipad (
        .clk(clk),
        .key(key_in),
        .pad(IPAD_BLOCK),
        .result(inner_input)
    )

    // instance of Xor
    xor xor_opad (
        .clk(clk),
        .key(key_in),
        .pad(OPAD_BLOCK),
        .result(outer_input)
    )

    //-----------------------------
    // Zustandsregister
    //-----------------------------
    always @(posedge clk or negedge reset) begin
        if (!reset)
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
                    hmac_state_next <= CONCAT_INNER_INPUT;
            end

            CONCAT_INNER_INPUT: begin
                //concat inner_input and message
                concat_inner[127:64]    <= inner_input;
                concat_inner[63:0]      <= msg_in;

                hmac_state_next <= PRODUCE_INNER_ASCON;
            end

            PRODUCE_INNER_ASCON: begin
                if (ascon_hash_ready)
                    hmac_state_next <= CONCAT_OUTER_INNER_ASCON;
            end

            CONCAT_OUTER_INNER_ASCON: begin
                // concat outer_input und inner_Ascon
                concat_outer[319:255]    <= outer_input;
                concat_outer[63:0]      <= ascon_hash_out;
                hmac_state_next <= PRODUCE_OUTER_ASCON;
            end

            PRODUCE_OUTER_ASCON: begin
                if (ascon_hash_ready)
                    hmac_state_next <= FINISH;
            end

            FINISH: begin
                hmac_ready <= 1'b1;
                hmac_state_next <= INIT;
            end

            default: begin 
                hmac_state_next <= INIT;
            end

        endcase
    end

endmodule
