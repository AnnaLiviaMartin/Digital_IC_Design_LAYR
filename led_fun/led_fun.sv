module led_fun (
    input logic clk,
    output logic [3 : 0] rleds,
    output logic gled 
);

    localparam WAITING_WIDTH = 21;
    localparam BLINKING_WIDTH = 4;

    localparam INIT = 0;
    localparam WAIT = 1;
    localparam RED_BLINK = 2;
    localparam GREEN_BLINK = 3;
    localparam RED_LOOP = 4;
    localparam RED_LOOP_INIT = 5;
    localparam CROSS_BLINK_INIT = 6;
    localparam CROSS_BLINK = 7;
    localparam CHILL = 8;

    logic [BLINKING_WIDTH - 1 : 0] blinkCount;
    logic [WAITING_WIDTH - 1 : 0] waitingCounter;

    logic [7 : 0] lastState;
    logic [7 : 0] state = INIT;

    always_ff @(posedge clk) begin
        case (state)
            INIT: begin
                blinkCount <= 1;
                waitingCounter <= 1;
                gled <= 0;
                rleds <= 0;
                state <= RED_BLINK;
            end
            WAIT: begin
                if (waitingCounter == 0) begin
                    waitingCounter <= 1;
                    state <= lastState;
                end
                else begin
                    waitingCounter <= waitingCounter + 1;
                end
            end
            RED_BLINK: begin
                if (blinkCount == 0) begin
                    blinkCount <= 1;
                    rleds <= 0;
                    state <= GREEN_BLINK;
                end
                else begin
                    rleds <= ~rleds;
                    
                    blinkCount <= blinkCount + 1;
                    lastState <= RED_BLINK;
                    state <= WAIT;
                end
            end
            GREEN_BLINK: begin
                if (blinkCount == 0) begin
                    blinkCount <= 1;
                    gled <= 0;
                    state <= RED_LOOP_INIT;
                end
                else begin
                    gled <= ~gled;
                    
                    blinkCount <= blinkCount + 1;
                    lastState <= GREEN_BLINK;
                    state <= WAIT;
                end
            end
            RED_LOOP_INIT: begin
                rleds <= 4'b1000;
                state <= RED_LOOP;
            end
            RED_LOOP: begin
                if (blinkCount == 0) begin
                    blinkCount <= 1;
                    rleds <= 0;
                    state <= CROSS_BLINK_INIT;
                end
                else begin
                    rleds <= (rleds == 4'b0001) ? 4'b1000 : rleds >> 1;
                    
                    blinkCount <= blinkCount + 1;
                    lastState <= RED_LOOP;
                    state <= WAIT;
                end
            end
            CROSS_BLINK_INIT: begin
                rleds <= 4'b0101;
                gled <= 1;
                state <= CROSS_BLINK;
            end
            CROSS_BLINK: begin
                if (blinkCount == 0) begin
                    blinkCount <= 1;
                    rleds <= 0;
                    gled <= 0;
                    state <= CHILL;
                end
                else begin
                    rleds <= ~rleds;

                    blinkCount <= blinkCount + 1;
                    lastState <= CROSS_BLINK;
                    state <= WAIT;
                end
            end
            CHILL: begin
                if (blinkCount == 0) begin
                    blinkCount <= 1;
                    state <= INIT;
                end
                else begin
                    blinkCount <= blinkCount + 1;
                    lastState <= CHILL;
                    state <= WAIT;
                end
            end
        endcase
    end

endmodule
