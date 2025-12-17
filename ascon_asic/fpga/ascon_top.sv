module ascon_statmachine_top (
    input logic clk,
    input logic rst_n,
    input logic [63:0] msg_in,
    input logic msg_start,
    input logic msg_last,
    output logic [0:255] hash_out,
    output wire hash_ready
);

// Internal signals
logic [319:0] state_in;
wire [319:0] state_out;
wire [2:0] current_state; // Updated to 3 bits to accommodate 5 states
wire [319:0] permutation_out;
wire [2:0] squeeze_counter;
logic permutation_done;
logic absorb_done;

logic msg_start_prev;
logic msg_start_short;
logic [1:0] pulse_counter;
//reg permutation_done;
localparam INIT = 3'b000;
localparam IDLE = 3'b001;
localparam ABSORB = 3'b010;
localparam PERMUTE = 3'b011;
localparam SQUEEZE = 3'b100;

// IV Vector
localparam [63:0] IV = 64'h0000080100cc0002;
reg [319:0] state_reg;


// State machine instantiation remains the same
ascon_state_machine state_machine (
    .clk(clk),
    .rst_n(rst_n),
    .msg_start(msg_start_short), // Use the two-cycle pulse signal
    .msg_last(msg_last),
    .permutation_done(permutation_done),
    .absorb_done(absorb_done),
    .current_state(current_state),
    .hash_ready(hash_ready),
    .squeeze_counter(squeeze_counter)
);

// Permutation module instantiation
ascon_permutation ascon_permutation (
    .clk(clk),
    .state_in(state_reg), // Directly using state_out
    .permutation_start(current_state == PERMUTE), // Start permutation when current state is PERMUTE
    .state_out(permutation_out),
    .permutation_done(permutation_done)
);

// State update logic
always @(posedge clk) begin
    if (!rst_n) begin
        state_reg <= {IV, 256'b0};     
    end else begin
        case (current_state)
            //init state initialized with IV vector
            INIT: state_reg <= {IV, 256'b0}; // INIT
            IDLE: begin 
                state_in = state_reg; // IDLE doesn't change state
                absorb_done <= 0;
            end
            ABSORB: begin
                    if(absorb_done == 0)
                        state_reg <= {state_reg[319:256] ^ msg_in, state_reg[255:0]}; // XOR the message with the current state
                        absorb_done <= 1;
                    if(absorb_done == 1) begin
                        absorb_done <= 0;
                        end
                    end 
            PERMUTE: begin   
                    if (permutation_done)
                        state_reg <= permutation_out; // PERMUTE only when permutation is done. Else prev. data is retained
                    end
                //when SQUEEZE hash_out is updated following the rule: 𝐻 ← 𝐻 0 ∥ 𝐻1 ∥ 𝐻2 ∥ 𝐻3 //TODO: check if the assignment is in the right bit order
            SQUEEZE: begin
                case (squeeze_counter)
                    0: hash_out[192:255] <= state_reg[319:256]; // H0
                    1: hash_out[128:191] <= state_reg[319:256]; // H1
                    2: hash_out[64:127] <= state_reg[319:256]; // H2
                    3: hash_out[0:63] <= state_reg[319:256]; // H3
                    default: hash_out = hash_out; // Fallback to current hash_out
                endcase
            end
            default: state_in = state_reg; // Fallback to current state
        endcase
    end
end



// Generate a two-cycle pulse for msg_start on rising edge
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        msg_start_prev <= 0;
        msg_start_short <= 0;
        pulse_counter <= 0;
    end else begin
        msg_start_prev <= msg_start;
        
        if (msg_start && !msg_start_prev) begin
            // Rising edge detected, start the pulse
            msg_start_short <= 1;
            pulse_counter <= 2'd2;
        end else if (pulse_counter > 0) begin
            // Continue the pulse for one more cycle
            pulse_counter <= pulse_counter - 1;
        end else begin
            // End of pulse
            msg_start_short <= 0;
        end
    end
end


endmodule
