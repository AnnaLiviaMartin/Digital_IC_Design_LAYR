module SPI_slave(clk, SCK, MOSI, MISO, SSEL, LEDS);

input clk, SCK, SSEL, MOSI;
output MISO;

output logic [7 : 0] LEDS;

// slave clock
// sync SCK to the FPGA clock using a 3-bit shift register
reg [2:0] SCKr;  always @(posedge clk) SCKr <= {SCKr[1:0], SCK};
wire SCK_risingedge = (SCKr[2:1]==2'b01);  // now we can detect SCK rising edges
wire SCK_fallingedge = (SCKr[2:1]==2'b10);  // and falling edges

// same thing for SSEL
reg [2:0] SSELr;  always @(posedge clk) SSELr <= {SSELr[1:0], SSEL};
wire SSEL_active = ~SSELr[1];  // SSEL is active low => start bei 0
/*
wire SSEL_startmessage = (SSELr[2:1]==2'b10);  // message starts at falling edge
wire SSEL_endmessage = (SSELr[2:1]==2'b01);  // message stops at rising edge
*/

// and for MOSI
reg [1:0] MOSIr;  always @(posedge clk) MOSIr <= {MOSIr[0], MOSI};
wire MOSI_data = MOSIr[1];
// we handle SPI in 8-bit format, so we need a 3 bits counter to count the bits as they come in
reg [2:0] bitcnt;

reg byte_received;  // high when a byte has been received
reg [7:0] byte_data_received;
reg [7:0] byte_data_sent;
reg [7:0] byte_data_received_backup;

// ascon

logic [63:0] ascon_msg_in;
logic [0:255] ascon_hash_out;
wire ascon_hash_ready;

logic ascon_rst_n;
logic ascon_msg_start;
logic ascon_msg_last;

reg is_resetting_ascon;
reg resetted_ascon;

ascon_statmachine_top ascon (
  .clk(clk),
  .rst_n(ascon_rst_n),
  .msg_in(ascon_msg_in),
  .msg_start(ascon_msg_start),
  .msg_last(ascon_msg_last),
  .hash_out(ascon_hash_out),
  .hash_ready(ascon_hash_ready)
);

/*
logic clk,
logic rst_n,
logic [63:0] msg_in,
input logic msg_start,
input logic msg_last,
output logic [0:255] hash_out,
output wire hash_ready
*/

// challenge response
localparam PAYLOAD_LENGTH = 256;

reg [PAYLOAD_LENGTH - 1 : 0] input_payload, output_payload;
reg [7:0] input_payload_index;
reg [7:0] output_payload_index;

reg is_receiving_payload;
reg is_sending_payload;

reg sent_payload;
reg received_payload;

localparam REQUEST_OPEN = 8'h01;
localparam CHALLENGE = 8'h02;
localparam CHALLENGE_ANSWER = 8'h03;
localparam GRANT_ACCESS = 8'h04;
localparam DENY_ACCESS = 8'h05;
localparam ERROR = 8'h06;

reg [63 : 0] secret_key = 64'b1010101010101010101010101010101010101010101010101010101010101010;
reg [255 : 0] challenge_result;

// random number generator

reg [PAYLOAD_LENGTH - 1 : 0] random_number_output;
reg [PAYLOAD_LENGTH - 1 : 0] nonce;

prng rng (
  .clk(clk),
  .random(random_number_output)
);

// oberer automat
localparam IDLE = 8'h00;
localparam CHECK_BYTE = 8'h01;
localparam SEND_RESPONSE = 8'h02;
logic [7:0] state, next_state;
reg [7:0] response_byte;
logic response_ready;
logic response_sent;

always @(posedge clk)
begin
  if(!SSEL_active)
    bitcnt <= 3'b000;
  else
  if(SCK_risingedge)
  begin
    bitcnt <= bitcnt + 3'b001;
    // implement a shift-left register (since we receive the data MSB first)
    byte_data_received <= {byte_data_received[6:0], MOSI_data};

    if (bitcnt == 3'b111) begin
      byte_data_received_backup <= {byte_data_received[6:0], MOSI_data};
    end
  end
end

always @(posedge clk) byte_received <= SSEL_active && SCK_risingedge && (bitcnt==3'b111);

initial begin
  LEDS <= 8'b00000000;
  response_byte <= 8'h00;
  ascon_msg_start <= 1'b0;
  ascon_msg_last <= 1'b0;
  ascon_rst_n <= 1'b0;
end

always_ff @(posedge clk) begin
  LEDS[7] <= 1;
  if (!SSEL_active) begin
    state <= IDLE;
    next_state <= IDLE;
    response_ready <= 1'b0;
    response_sent <= 1'b0;

    sent_payload <= 1'b0;
    received_payload <= 1'b0;
  end
  else
    state <= next_state;

  if (state == IDLE && byte_received) begin
    next_state <= CHECK_BYTE;
    response_ready <= 1'b0;
    response_sent  <= 1'b0;
  end
  else if (state == CHECK_BYTE && response_ready)
    next_state <= SEND_RESPONSE;
  else if (state == SEND_RESPONSE && response_sent)
    next_state <= IDLE;

  if (is_resetting_ascon) begin
    if (!ascon_rst_n) begin
      ascon_rst_n <= 1'b1;
      LEDS[1] <= 1;
    end
    else begin
      //ascon_rst_n <= 1'b0;
      resetted_ascon <= 1'b1;
      is_resetting_ascon <= 1'b0;
      LEDS[2] <= 1;
    end
  end

  if (resetted_ascon) begin
    //ascon_msg_start <= 1'b1;
    //ascon_msg_last <= 1'b1;
    //resetted_ascon <= 1'b0;
    ascon_msg_in <= 64'hFFFFFFFFFFFFFFFF;
    
    if (!ascon_msg_last && !ascon_msg_start) begin
      ascon_msg_start <= 1'b1;
      LEDS[3] <= 1;
    end
    else if (ascon_msg_start) begin
      ascon_msg_last <= 1'b1;
      ascon_msg_start <= 1'b0;
      LEDS[4] <= 1;
    end else begin
      resetted_ascon <= 1'b0;
      LEDS[5] <= 1;
    end
  end

  if (ascon_hash_ready) begin
    ascon_msg_last <= 1'b0;
    nonce <= ascon_hash_out;
    output_payload <= ascon_hash_out;
    response_ready <= 1'b1;
    is_sending_payload <= 1'b1;
    LEDS[6] <= 1;
  end

  if (state == CHECK_BYTE && !is_receiving_payload) begin
    case (byte_data_received_backup)
      0: begin
        response_ready <= 1'b1;
        is_sending_payload <= 1'b1;
      end
      REQUEST_OPEN: begin
        response_byte <= CHALLENGE;

        is_resetting_ascon <= 1'b1;

        /*response_ready <= 1'b1;
        //output_payload <= 256'h112233445566778899AABBCCDDEEFF_0102030405060708090A0B0C0D0E0F_1A1B;
        nonce <= random_number_output;
        output_payload <= random_number_output;
        is_sending_payload <= 1'b1;
        */
        LEDS[0] <= 1;
      end
      CHALLENGE: begin
        response_byte <= CHALLENGE_ANSWER;
        if (!received_payload)
          is_receiving_payload <= 1'b1;
        else
          is_sending_payload <= 1'b1;
        
        //response_ready <= 1'b1;
      end
      CHALLENGE_ANSWER: begin
        is_receiving_payload <= 1'b1;
        //response_byte <= DENY_ACCESS;
        if (received_payload) begin
          response_byte <= GRANT_ACCESS;
          response_ready <= 1'b1;
          //is_receiving_payload <= 1'b0;
          is_sending_payload <= 1'b1;
        end
        //response_ready <= 1'b1;
      end
      GRANT_ACCESS: begin
        state <= IDLE;
      end
      DENY_ACCESS: begin
        state <= IDLE;
      end
      ERROR: begin
        response_byte <= ERROR;
        response_ready <= 1'b1;
      end
      default: begin
        response_byte <= 8'h06;
        response_ready <= 1'b1;
      end
    endcase
  end
  
  if (is_receiving_payload && byte_received) begin
    //input_payload[PAYLOAD_LENGTH - 1 - input_payload_index * 8 : PAYLOAD_LENGTH - 1 - input_payload_index * 8 - 7] <= byte_data_received_backup;
    input_payload[7 + input_payload_index * 8 : input_payload_index * 8] <= byte_data_received_backup;
    input_payload_index <= input_payload_index + 1;
    if (7 + input_payload_index * 8 >= PAYLOAD_LENGTH) begin
      is_receiving_payload <= 1'b0;
      received_payload <= 1'b1;
      input_payload_index <= 8'b0;
      //output_payload <= input_payload;
    end
  end

  if (SCK_fallingedge && state == SEND_RESPONSE && bitcnt == 3'b000 && response_ready)
    response_sent <= 1'b1;

  if (!SSEL_active) //unterer Automat
    byte_data_sent <= 8'h00;
  else if (SCK_fallingedge) begin
    if (bitcnt != 3'b000) begin // runterrechnen von clk, nur bei langsamer clk machen wir etwas
      byte_data_sent <= {byte_data_sent[6:0], 1'b0};
    end
    if (state == SEND_RESPONSE) begin
      if (is_sending_payload) begin
        byte_data_sent <= output_payload[7 + output_payload_index * 8 : output_payload_index * 8];
        output_payload_index <= output_payload_index + 1;
        if (7 + output_payload_index * 8 >= PAYLOAD_LENGTH) begin
          is_sending_payload <= 1'b0;
          sent_payload <= 1'b1;
          output_payload_index <= 8'b0;
        end
      end
      else
        byte_data_sent <= 8'h10;
    end
  end

end

assign MISO = byte_data_sent[7];  // send MSB first

endmodule