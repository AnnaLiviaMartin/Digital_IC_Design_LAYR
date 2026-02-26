`timescale 1ns/1ps
module SPI_slave(clk, SCK, MOSI, MISO, SSEL, LEDS);
input clk, SCK, SSEL, MOSI;
output MISO;
output logic [7:0] LEDS;

// sync SCK to the FPGA clock using a 3-bit shift register
reg [2:0] SCKr;  
always @(posedge clk) SCKr <= {SCKr[1:0], SCK};
wire SCK_risingedge = (SCKr[2:1]==2'b01);
wire SCK_fallingedge = (SCKr[2:1]==2'b10);

// same thing for SSEL
reg [2:0] SSELr;  
always @(posedge clk) SSELr <= {SSELr[1:0], SSEL};
wire SSEL_active = ~SSELr[1];

// and for MOSI
reg [1:0] MOSIr;  
always @(posedge clk) MOSIr <= {MOSIr[0], MOSI};
wire MOSI_data = MOSIr[1];

// SPI counters & data
reg [2:0] bitcnt;
reg byte_received;
reg [7:0] byte_data_received;
reg [7:0] byte_data_sent;

// FSM
localparam IDLE = 8'h00;
localparam CHECK_BYTE = 8'h01;
localparam SEND_RESPONSE = 8'h02;
logic [7:0] state, next_state;
reg [7:0] response_byte;
reg [7:0] received_bytes;
logic response_ready;
logic response_sent;

// ============= FIX 1: Bitcounter & Data Receive =============
always @(posedge clk) begin
  if(~SSEL_active)
    bitcnt <= 3'b000;
  else if(SCK_risingedge) begin
    bitcnt <= bitcnt + 3'b001;
    byte_data_received <= {byte_data_received[6:0], MOSI_data};
  end
end

// ============= FIX 2: Byte received - delayed trigger =============
always @(posedge clk) begin
  if (SCK_risingedge && SSEL_active && bitcnt == 3'b111)
    byte_received <= 1'b1;
  else 
    byte_received <= 1'b0;
end

// LEDs
initial LEDS <= 8'b00000000;

always @(posedge clk) begin
  LEDS[7] <= 1;
  if(byte_received) LEDS[6] <= 1;
  if (state == SEND_RESPONSE) LEDS[2] <= 1;
  if (state == CHECK_BYTE) LEDS[1] <= 1;
  if (state == IDLE) LEDS[0] <= 1;
end

// ============= FIX 3: FSM mit vollständigem Reset =============
always_ff @(posedge clk) begin
  if (!SSEL_active) begin
    state <= IDLE;
    next_state <= IDLE;
    response_ready <= 1'b0;
    response_byte <= 8'h00;
    response_sent <= 1'b0;
    byte_received <= 1'b0;
    bitcnt <= 3'b0;
  end else begin
    state <= next_state;
    
    if (state == IDLE && byte_received) begin
      next_state <= CHECK_BYTE;
      received_bytes <= byte_data_received;
    end else if (state == CHECK_BYTE && response_ready)
      next_state <= SEND_RESPONSE;
    else if (state == SEND_RESPONSE && bitcnt == 3'b111 && response_sent)
      next_state <= IDLE;
    else
      next_state <= state;
    
    // Response generieren
    if (SCK_fallingedge && state == CHECK_BYTE) begin
      response_byte <= 8'h04;  // Immer 0x04
      response_ready <= 1'b1;
    end
  end
end

// ============= FIX 4: MISO Shift Register =============
always @(posedge clk) begin
  if (~SSEL_active)
    byte_data_sent <= 8'h00;
  else if (SCK_fallingedge) begin
    if (response_ready && bitcnt == 0) begin  // Load bei Start
      byte_data_sent <= response_byte;
      response_sent <= 1'b1;
    end else begin  // Normal shift
      byte_data_sent <= {byte_data_sent[6:0], 1'b0};
    end
  end
end

assign MISO = byte_data_sent[7];

endmodule
