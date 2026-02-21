// Finite Automaton:
//   - Input  '3' → Output 'b' (0x62)
//   - Input  other      → Output 'c' (0x63)
//
// Implemented as a Mealy machine with one state (S0).
// Outputs are registered (one-cycle latency after valid_in).

module char_automaton (
    input  wire       clk,
    input  wire       rst_n,     // active-low synchronous reset
    input  wire       valid_in,  // pulse high when char_in is valid
    input  wire [7:0] char_in,   // ASCII input character
    output reg        valid_out, // high one cycle after valid_in
    output reg  [7:0] char_out   // ASCII output character
);
    // ASCII constants
    localparam [7:0] ASCII_3 = 8'h03; // '3'
    localparam [7:0] ASCII_B = 8'h62; // 'b'
    localparam [7:0] ASCII_C = 8'h63; // 'c'

    // States
    localparam [0:0] S0 = 1'b0; // only one state needed
    reg [0:0] state;

    always @(posedge clk) begin
        if (!rst_n) begin
            state     <= S0;
            valid_out <= 1'b0;
            char_out  <= 8'h00;
        end else begin
            valid_out <= valid_in;   // propagate validity
            state     <= S0;         // automaton stays in S0
            if (valid_in) begin
                if (char_in == ASCII_3)
                    char_out <= ASCII_B;  // 'a' → 'b'
                else
                    char_out <= ASCII_C;  // anything else → 'c'
            end
        end
    end
endmodule