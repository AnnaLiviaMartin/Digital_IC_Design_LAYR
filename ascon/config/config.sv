`ifndef INCL_CONFIG
`define INCL_CONFIG

// UROL: Number of Ascon-p rounds per clock cycle
// CCW: Width of the data buses
localparam logic [3:0] UROL = 1;
localparam unsigned CCW = 64;

// Ascon parameters
localparam unsigned ROUNDS_A = 12;
localparam unsigned ROUNDS_B = 8;

// Initialization Vectors for ASCON-Hash256
localparam logic [63:0] IV_HASH = 64'h0000080100cc0002;  // ASCON-Hash256

`endif  // INCL_CONFIG
