`include "config.sv"
`timescale 1ns / 1ps

module permutation
    import ascon_pkg::t_state_array;
(
    input  logic                 clock,                    //! Clock signal
    input  logic                 reset_n,                  //! Reset signal, active low
    input  logic                 i_sys_enable,             //! System enable signal, active high
    input  logic                 i_mux_select,             //! Mux select signal, active high
    input  logic                 i_enable_xor_key_begin,   //! Enable XOR with Key, active high
    input  logic                 i_enable_xor_data_begin,  //! Enable XOR with Data, active high
    input  logic                 i_enable_xor_key_end,     //! Enable XOR with Key, active high
    input  logic                 i_enable_xor_lsb_end,     //! Enable XOR with LSB, active high
    input  logic                 i_enable_cipher_reg,      //! Enable cipher register, active high
    input  logic                 i_enable_tag_reg,         //! Enable tag register, active high
    input  logic                 i_enable_state_reg,       //! Enable state register, active high
    input  t_state_array         i_state,                  //! Input state array
    input  logic         [  3:0] i_round,                  //! Input round number
    input  logic         [ 63:0] i_data,                   //! Input data
    input  logic         [127:0] i_key,                    //! Input key
    output t_state_array         o_state,                  //! Output state array
    output logic         [ 63:0] o_cipher,                 //! Output cipher
    output logic         [127:0] o_tag                     //! Output tag
);

  //
  // Signal definition
  //
  t_state_array
  state_mux_output,                   //! Output of the input Multiplexer
  state_xor_begin_output,             //! Output of the xor_begin module
  state_adder_output,                 //! Output of the addition_layer module
  state_substitution_layer_output,    //! Output of the substitution_layer module
  state_diffusion_output,             //! Output of the diffusion_layer module
  state_xor_end_output,               //! Output of the xor_end module
  state_output_reg;                   //! Output of the register

  logic [ 63:0] o_cipher_reg;             //! Output of the cipher register
  logic [127:0] o_tag_reg;                //! Output of the tag register

  //
  // Input Multiplexer
  //
  assign state_mux_output = (i_mux_select == 1'b0) ? i_state : state_output_reg;

  //
  // Modules instantiation
  //

  // Instantiate xor_begin
  xor_begin xor_begin_1 (
      .i_state          (state_mux_output),
      .i_data           (i_data),
      .i_key            (i_key),
      .i_enable_xor_key (i_enable_xor_key_begin),
      .i_enable_xor_data(i_enable_xor_data_begin),
      .o_state          (state_xor_begin_output)
  );

  // Instantiate addition_layer
  addition_layer addition_layer_1 (
      .i_round(i_round),
      .i_state(state_xor_begin_output),
      .o_state(state_adder_output)
  );

  // Instantiate substitution_layer_generic
  substitution_layer #(
      .G_NUM_SBOXES(64)
  ) substitution_layer_1 (
      .i_state(state_adder_output),
      .o_state(state_substitution_layer_output)
  );

  // Instantiate diffusion_layer
  diffusion_layer diffusion_layer_1 (
      .i_state(state_substitution_layer_output),
      .o_state(state_diffusion_output)
  );

  // Instantiate xor_end
  xor_end xor_end_1 (
      .i_state         (state_diffusion_output),
      .i_key           (i_key),
      .i_enable_xor_key(i_enable_xor_key_end),
      .i_enable_xor_lsb(i_enable_xor_lsb_end),
      .o_state         (state_xor_end_output)
  );

    //
    // Register process
    //

    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            state_output_reg <= '{default: 0};
            o_cipher_reg     <= 0;
            o_tag_reg        <= 0;
        end
        else if (i_sys_enable) begin

            // State output assignment
            if (i_enable_state_reg) begin
                state_output_reg <= state_xor_end_output;
            end

            // Cipher output assignment
            if (i_enable_cipher_reg) begin
                o_cipher_reg <= state_xor_begin_output[0];
            end

            // Tag output assignment
            if (i_enable_tag_reg) begin
                o_tag_reg <= {state_xor_end_output[3], state_xor_end_output[4]};
            end
        end
        else begin
            // Soft reset
            state_output_reg <= '{default: 0};
            o_cipher_reg     <= 0;
            o_tag_reg        <= 0;
        end
    end

    //
    // Output assignment
    //

    assign o_state  = state_output_reg;
    assign o_cipher = o_cipher_reg;
    assign o_tag    = o_tag_reg;

endmodule
