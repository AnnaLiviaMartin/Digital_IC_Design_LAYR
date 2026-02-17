//Dieses Modul implementiert einen einfachen SPI-Slave in SystemVerilog für eine FPGA. 
// Es empfängt Bytes über MOSI vom Master, zählt Nachrichten und 
// sendet eine einfache Bestätigung zurück über MISO.
//SPI-Mode 0 (CPOL=0, CPHA=0), Sample auf Rising, Change auf Falling für Slave
//SPI-Master: Daten an gegenüberliegenden Flanke (fallend) ändert, SPI Mode 0/3
//Der Code selbst sorgt nicht aktiv für „Mitte der Bitzeit“, sondern verlässt sich auf das Standard-SPI-Timing: 
// Master ändert Daten an einer Flanke, Slave liest an der nächsten. Diese nächste Flanke liegt in der Mitte 
// des Bitfensters, wenn der Master sich korrekt verhält.
module SPI_slave (
    input  logic clk,
    input  logic SCK, SSEL, MOSI,
    output logic MISO
);

// Sync SCK to the FPGA clock using a 3-bit shift register
logic [2:0] SCKr;
always_ff @(posedge clk) begin
    SCKr <= {SCKr[1:0], SCK};
end
logic SCK_risingedge = (SCKr[2:1] == 2'b01);  // Detect SCK rising edges
logic SCK_fallingedge = (SCKr[2:1] == 2'b10); // Detect SCK falling edges

// Same for SSEL
logic [2:0] SSELr;  // starts when low
always_ff @(posedge clk) begin
    SSELr <= {SSELr[1:0], SSEL};
end
logic SSEL_active = ~SSELr[1];                 // SSEL active low
logic SSEL_startmessage = (SSELr[2:1] == 2'b10); // Message starts at falling edge
logic SSEL_endmessage = (SSELr[2:1] == 2'b01);   // Message stops at rising edge

// For MOSI (2-bit suffices)
logic [1:0] MOSIr;
always_ff @(posedge clk) begin
    MOSIr <= {MOSIr[0], MOSI};
end
logic MOSI_data = MOSIr[1];

// Bit counter for 8-bit reception
logic [2:0] bitcnt;
logic byte_received;
logic [7:0] byte_data_received;

// wenn SSEL aktiv: ein Bit aus MOSI (synchronisiert = MOSI_data) in das 8-Bit-Register byte_data_received eingeschoben
// Einlesen bei SCK_risingedge: 
always_ff @(posedge clk) begin
    if (~SSEL_active)
        bitcnt <= 3'b000;
    else if (SCK_risingedge) begin
        bitcnt <= bitcnt + 3'b001;
        byte_data_received <= {byte_data_received[6:0], MOSI_data}; // Shift in MSB first
    end
end

// byte_received: Platzhalter für Logik
always_ff @(posedge clk) begin
    byte_received <= SSEL_active && SCK_risingedge && (bitcnt == 3'b111);
end

// Transmission counter
logic [7:0] cnt;
always_ff @(posedge clk) begin
    if (SSEL_startmessage) cnt <= cnt + 8'h1;
end

logic [7:0] byte_data_sent;
always_ff @(posedge clk) begin
    if (SSEL_active) begin
        if (SSEL_startmessage)
            byte_data_sent <= 8'h41;  // First byte: message count
        else if (SCK_fallingedge) begin
            if (bitcnt == 3'b000)
                byte_data_sent <= 8'h41; // Then send 0s
            else
                byte_data_sent <= {byte_data_sent[6:0], 1'b0};
        end
    end
end

assign MISO = byte_data_sent[7]; // Send MSB first

endmodule