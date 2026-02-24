module SPI_slave(clk, SCK, MOSI, MISO, SSEL, LED);
input clk;

input SCK, SSEL, MOSI;
output MISO;

output LED;

// sync SCK to the FPGA clock using a 3-bit shift register
reg [2:0] SCKr;  always @(posedge clk) SCKr <= {SCKr[1:0], SCK};
wire SCK_risingedge = (SCKr[2:1]==2'b01);  // now we can detect SCK rising edges
wire SCK_fallingedge = (SCKr[2:1]==2'b10);  // and falling edges

// same thing for SSEL
reg [2:0] SSELr;  always @(posedge clk) SSELr <= {SSELr[1:0], SSEL};
wire SSEL_active = ~SSELr[1];  // SSEL is active low => start bei 0
wire SSEL_startmessage = (SSELr[2:1]==2'b10);  // message starts at falling edge
wire SSEL_endmessage = (SSELr[2:1]==2'b01);  // message stops at rising edge

// and for MOSI
reg [1:0] MOSIr;  always @(posedge clk) MOSIr <= {MOSIr[0], MOSI};
wire MOSI_data = MOSIr[1];
// we handle SPI in 8-bit format, so we need a 3 bits counter to count the bits as they come in
reg [2:0] bitcnt;

reg byte_received;  // high when a byte has been received
reg [7:0] byte_data_received;

always @(posedge clk)
begin
  if(~SSEL_active)
    bitcnt <= 3'b000;
  else
  if(SCK_risingedge)
  begin
    bitcnt <= bitcnt + 3'b001;
    // implement a shift-left register (since we receive the data MSB first)
    byte_data_received <= {byte_data_received[6:0], MOSI_data};
  end
end

always @(posedge clk) byte_received <= SSEL_active && SCK_risingedge && (bitcnt==3'b111);

// we use the LSB of the data received to control an LED
reg LED;
always @(posedge clk) if(byte_received) LED <= byte_data_received[0];
reg [7:0] byte_data_sent;
 
// oberer automat
localparam IDLE = 8'h00;
localparam CHECK_BYTE = 8'h01;
localparam SEND_RESPONSE = 8'h02;
logic [1:0] state, next_state;
logic [7:0] response_byte;
logic [0:0] response_ready; // tag
logic [0:0] response_send; // tag

always_ff @(posedge clk) begin
    if (!SSEL_active) begin
        state <= IDLE;
        next_state <= IDLE;
        response_ready <= 1'b0;
        response_byte <= 8'h00;
        response_send <= 1'b0;
    end
    else
        state <= next_state;

    if (state == IDLE && byte_received)
        next_state <= CHECK_BYTE;
    else if (state == CHECK_BYTE && response_ready)
        next_state <= SEND_RESPONSE;
    else if (state == SEND_RESPONSE && bitcnt == 3'b111 && response_send)
        next_state <= IDLE;
    
    if (SCK_fallingedge && state == CHECK_BYTE) begin
        /* if (byte_data_received == 8'h03)
            response_byte <= 8'h05;
        else */
        response_byte <= 8'h4; //byte_data_received;
        response_ready <= 1'b1;
    end
end

// unterer automat
always @(posedge clk) // schnelle clk
  if (~SSEL_active)
      byte_data_sent <= 8'h00;
  else if (response_ready) begin
      byte_data_sent <= response_byte;
      response_send <= 1'b1;
  end
  else if (SCK_fallingedge && bitcnt != 3'b000) // runterrechnen von clk, nur bei langsamer clk machen wir etwas
      byte_data_sent <= {byte_data_sent[6:0], 1'b0};

assign MISO = byte_data_sent[7];  // send MSB first

endmodule