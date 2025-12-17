module hmac_fsm (
    input  logic clk,
    input  logic rst_n
);

  // 11 HMAC-Ascon Zustände als localparams
  localparam logic [3:0] INIT                       = 4'd0;
  localparam logic [4:0] SAVE_MESSAGE               = 4'd1;
  localparam logic [3:0] CREATE_INNER_INPUT         = 4'd2;
  localparam logic [3:0] CONCAT_INNER_INPUT         = 4'd3;
  localparam logic [3:0] INNER_ASCON                = 4'd4;
  localparam logic [3:0] SAVE_INNER_ASCON           = 4'd5;
  localparam logic [3:0] CREATE_OUTER_INPUT         = 4'd6;
  localparam logic [3:0] CONCAT_OUTER_INNER_ASCON   = 4'd7;
  localparam logic [3:0] OUTER_ASCON                = 4'd8;
  localparam logic [3:0] SOLUTION                   = 4'd9;

  logic [3:0] state, state_next;

  // Zustandsregister
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      state <= INIT;
    else
      state <= state_next;
  end

  // Nur Zustandsübergänge (zyklisch)
  always_comb begin
    state_next = state;

    unique case (state)
      INIT:                   state_next = SAVE_MESSAGE;
      SAVE_MESSAGE:           state_next = CREATE_INNER_INPUT;
      CREATE_INNER_INPUT:     state_next = CONCAT_INNER_INPUT;
      CONCAT_INNER_INPUT:     state_next = INNER_ASCON;
      INNER_ASCON:            state_next = SAVE_INNER_ASCON;
      SAVE_INNER_ASCON:       state_next = CREATE_OUTER_INPUT;
      CREATE_OUTER_INPUT:     state_next = CONCAT_OUTER_INNER_ASCON;
      CONCAT_OUTER_INNER_ASCON: state_next = OUTER_ASCON;
      OUTER_ASCON:            state_next = SOLUTION;
      SOLUTION:               state_next = INIT;
      default:                state_next = INIT;
    endcase
  end

endmodule
