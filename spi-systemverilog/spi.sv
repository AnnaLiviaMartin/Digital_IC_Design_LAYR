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
  if(~SSEL_active)
    bitcnt <= 3'b000;
  else
  if(SCK_risingedge)
  begin
    bitcnt <= bitcnt + 3'b001;
    // implement a shift-left register (since we receive the data MSB first)
    byte_data_received <= {byte_data_received[6:0], MOSI_data};

    if (bitcnt == 3'b111) begin
      byte_data_received_backup <= {byte_data_received[6:0], MOSI_data};
      LEDS[4] <= LEDS[5] == 1;
      LEDS[5] <= 1;
    end
  end
end

always @(posedge clk) byte_received <= SSEL_active && SCK_risingedge && (bitcnt==3'b111);

initial begin
  LEDS <= 8'b00000000;
  response_byte <= 8'h00;
end

always @(posedge clk) begin
  LEDS[7] <= 1;

  if (byte_received)
    LEDS[6] <= 1;
  
  if (state == SEND_RESPONSE)
    LEDS[2] <= 1;
  
  if (state == CHECK_BYTE)
    LEDS[1] <= 1;

  if (state == IDLE)
    LEDS[0] <= 1;
    
end

always_ff @(posedge clk) begin
    if (!SSEL_active) begin
        state <= IDLE;
        next_state <= IDLE;
        response_ready <= 1'b0;
        response_sent <= 1'b0;
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
    // FIX: In SEND_RESPONSE sofort zu CHECK_BYTE bei byte_received,
    // OHNE auf response_sent zu warten. response_sent kommt erst beim naechsten
    // bitcnt==0, also NACH byte_received – sie ueberlappen sich nie.
    // Der untere Automat shiftet byte_data_sent weiterhin unabhaengig aus.
    else if (state == SEND_RESPONSE && byte_received) begin
        next_state <= CHECK_BYTE;
        response_ready <= 1'b0;
        response_sent  <= 1'b0;
    end
    else if (state == SEND_RESPONSE && response_sent)
        next_state <= IDLE;
    
    if (SCK_fallingedge && state == CHECK_BYTE) begin
        if (byte_data_received_backup == 8'h3)
          response_byte <= 8'h2;
        else
          response_byte <= 8'h4;
        response_ready <= 1'b1;
    end

    if (SCK_fallingedge && state == SEND_RESPONSE && bitcnt == 3'b000 && response_ready)
        response_sent <= 1'b1;
end

// unterer automat
always @(posedge clk) // schnelle clk
  if (!SSEL_active)
      byte_data_sent <= 8'h00;
  else if (SCK_fallingedge) begin
      if (bitcnt != 3'b000) begin // runterrechnen von clk, nur bei langsamer clk machen wir etwas
        byte_data_sent <= {byte_data_sent[6:0], 1'b0};
      end
      // FIX: byte_data_sent direkt in CHECK_BYTE laden (gleiche Flanke wie Berechnung).
      // response_byte ist wegen non-blocking noch nicht aktuell -> Logik dupliziert.
      else if (state == CHECK_BYTE) begin
        if (byte_data_received_backup == 8'h3)
          byte_data_sent <= 8'h2;
        else
          byte_data_sent <= byte_data_received_backup;
      end
  end

assign MISO = byte_data_sent[7];  // send MSB first

endmodule