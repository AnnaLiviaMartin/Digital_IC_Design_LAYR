module ascon_state_machine (
    input logic clk,
    input logic rst_n,
    input logic msg_start,
    input logic msg_last,
    input logic permutation_done,
    input logic absorb_done,
    output reg [2:0] current_state,
    output reg hash_ready,
    output reg [2:0] squeeze_counter
);


localparam INIT = 3'b000;
localparam IDLE = 3'b001;
localparam ABSORB = 3'b010;
localparam PERMUTE = 3'b011;
localparam SQUEEZE = 3'b100;

// State machine logic

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        current_state <= INIT;
        squeeze_counter <= 2'd0;
        hash_ready <= 1'b0;
    end else begin
        case (current_state)
            INIT: begin //reset all values, go to IDLE where IV is set to state_reg and then go to PERMUTE
                current_state <= PERMUTE;
                squeeze_counter <= 2'd0;
                hash_ready <= 1'b0;
            end
            IDLE: begin
                if (msg_start == 1'b1) begin
                    current_state <= ABSORB;
                end else begin
                    current_state <= IDLE;
                end
            end
            ABSORB: begin //absorb data: msg is written into state. Then go to PERMUTE. If msg_last is 1, go to SQUEEZE
                if(msg_start == 1'b1 && absorb_done == 1'b1)
                    current_state <= PERMUTE;
                else if(msg_start == 1)
                    current_state <= ABSORB;
                else
                    current_state <= IDLE;
            end
            PERMUTE: begin //permute state. If last round, go to IDLE. Else go to PERMUTE
                if(msg_last == 1'b0 && permutation_done) begin
                    current_state <= IDLE;
                end else if(msg_last == 1'b1 && permutation_done) begin //msg_last has to be 1 while squeezing
                    current_state <= SQUEEZE;
                end else begin
                    
                end
            end
            SQUEEZE: begin //while squeezing, msg_last needs to be 1 to return to squeeze after permute
                if (squeeze_counter == 3) begin
                    current_state <= IDLE;
                    hash_ready = 1'b1;
                end else begin
                    current_state <= PERMUTE;
                    squeeze_counter <= squeeze_counter + 1;
                end if(hash_ready == 1'b1)
                        squeeze_counter <= 2'd0;
            end
            default: begin
                current_state <= IDLE;
                
            end
        endcase
    end
end

endmodule
