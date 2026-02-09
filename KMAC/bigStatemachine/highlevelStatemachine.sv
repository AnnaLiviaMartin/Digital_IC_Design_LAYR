`timescale 1ns/1ps

// -------------------------------------------------------------------
// FSM für Ascon-KMAC Prozess als Schloss oder Schlüssel
// -------------------------------------------------------------------
module auth_kmac_fsm #(
    parameter int RATE_BITS = 256,
    parameter int CAPACITY  = 128
)(
    input  logic                 clk,
    input  logic                 rst_n,

    // Rollenwahl: 0 = Schloss, 1 = Schlüssel
    input  logic                 is_key,

    // globaler Start / Fertig
    input  logic                 start,
    output logic                 ready,       // Prozess abgeschlossen

    // Schloss-spezifisch
    output logic                 geh_auf,     // Tür öffnen, wenn auth ok (nur Schloss)
    
    // gemeinsamer geheimer Schlüssel k
    input  logic [CAPACITY-1:0]  key,

    // Abstraktes Kommunikations-Interface (z.B. Richtung SPI-Kompo)
    // Schloss -> Schlüssel: Challenge
    output logic [RATE_BITS-1:0] challenge_out,
    output logic                 challenge_out_valid,
    input  logic [RATE_BITS-1:0] challenge_in,
    input  logic                 challenge_in_valid,

    // Schlüssel -> Schloss: Response (Tag)
    output logic [255:0]         response_out,
    output logic                 response_out_valid,
    input  logic [255:0]         response_in,
    input  logic                 response_in_valid
);

  // ---------------- PRNG für Challenge (Schloss) ----------------
  logic [255:0] prng_random;

  prng prng_i (
    .clk    (clk),
    .random (prng_random)
  );

  // ---------------- KMAC/Ascon-Block ----------------
  logic                 kmac_start;
  logic [RATE_BITS-1:0] msg_block;
  logic [15:0]          msg_bit_len;
  logic [255:0]         kmac_out;
  logic                 kmac_done;

  // Hash unbenutzt
  logic                 hash_start;
  logic [63:0]          hash_msg_in;
  logic                 hash_msg_last;
  logic [255:0]         hash_out;
  logic                 hash_ready;
  logic [2:0]           kmac_top_state;

  assign hash_start    = 1'b0;
  assign hash_msg_in   = '0;
  assign hash_msg_last = 1'b0;

  kmac_ascon_top #(
    .RATE_BITS (RATE_BITS),
    .CAPACITY  (CAPACITY)
  ) kmac_ascon_i (
    .clk          (clk),
    .rst_n        (rst_n),
    .kmac_start   (kmac_start),
    .key          (key),
    .msg_block    (msg_block),
    .msg_bit_len  (msg_bit_len),
    .hash_start   (hash_start),
    .hash_msg_in  (hash_msg_in),
    .hash_msg_last(hash_msg_last),
    .kmac_out     (kmac_out),
    .kmac_done    (kmac_done),
    .hash_out     (hash_out),
    .hash_ready   (hash_ready),
    .top_state    (kmac_top_state)
  );

  // ---------------- Zustände der FSM ----------------
  typedef enum logic [4:0] {
    S_IDLE,

    // Schloss-Pfad
    S_L_GET_CHALLENGE,
    S_L_SEND_CHALLENGE,
    S_L_WAIT_RESPONSE,
    S_L_KMAC_START,
    S_L_KMAC_WAIT,
    S_L_COMPARE,
    S_L_DONE,

    // Schlüssel-Pfad
    S_K_WAIT_CHALLENGE,
    S_K_KMAC_START,
    S_K_KMAC_WAIT,
    S_K_SEND_RESPONSE,
    S_K_DONE
  } state_t;

  state_t               state, next_state;
  logic [RATE_BITS-1:0] challenge_reg;
  logic [255:0]         response_reg;

  assign challenge_out = challenge_reg;
  assign response_out  = kmac_out;   // Tag geht als Response raus

  // ---------------- Zustandsregister + Datenspeicher ----------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state         <= S_IDLE;
      challenge_reg <= '0;
      response_reg  <= '0;
    end else begin
      state <= next_state;

      // Schloss: Challenge aus PRNG snapshotten
      if (state == S_L_GET_CHALLENGE) begin
        challenge_reg <= prng_random[RATE_BITS-1:0];
      end

      // Schloss: Response (Tag) vom Schlüssel übernehmen
      if (state == S_L_WAIT_RESPONSE && response_in_valid) begin
        response_reg <= response_in;
      end

      // Schlüssel: Challenge vom Schloss übernehmen
      if (state == S_K_WAIT_CHALLENGE && challenge_in_valid) begin
        challenge_reg <= challenge_in;
      end
    end
  end

  // ---------------- Kombinatorische Logik ----------------
  always_comb begin
    // Defaultwerte
    next_state          = state;
    ready               = 1'b0;
    geh_auf             = 1'b0;

    challenge_out_valid = 1'b0;
    response_out_valid  = 1'b0;

    kmac_start          = 1'b0;
    msg_block           = challenge_reg;
    msg_bit_len         = 16'd256;   // 256-Bit Challenge

    unique case (state)
      // -------------------------------------------------
      // IDLE: warte auf Start und Rolle (Schloss/Schlüssel)
      // -------------------------------------------------
      S_IDLE: begin
        if (start) begin
          if (is_key)
            next_state = S_K_WAIT_CHALLENGE;   // Schlüssel-Flow
          else
            next_state = S_L_GET_CHALLENGE;    // Schloss-Flow
        end
      end

      // -------------------------------------------------
      // SCHLOSS
      // -------------------------------------------------
      // 1) Challenge aus PRNG nehmen
      S_L_GET_CHALLENGE: begin
        next_state = S_L_SEND_CHALLENGE;
      end

      // 2) Challenge an Schlüssel senden
      S_L_SEND_CHALLENGE: begin
        challenge_out_valid = 1'b1;           // 1 Takt lang gültig
        next_state          = S_L_WAIT_RESPONSE;
      end

      // 3) Auf Response (Tag) vom Schlüssel warten
      S_L_WAIT_RESPONSE: begin
        if (response_in_valid)
          next_state = S_L_KMAC_START;
      end

      // 4) KMAC lokal starten (Challenge_reg || k)
      S_L_KMAC_START: begin
        kmac_start = 1'b1;
        next_state = S_L_KMAC_WAIT;
      end

      // 5) Auf KMAC-Fertig warten
      S_L_KMAC_WAIT: begin
        kmac_start = 1'b1;
        if (kmac_done)
          next_state = S_L_COMPARE;
      end

      // 6) Vergleich: kmac_out == response_reg ? -> geh_auf
      S_L_COMPARE: begin
        ready  = 1'b1;
        geh_auf = (kmac_out == response_reg);
        next_state = S_L_DONE;
      end

      // 7) Fertig, auf neues Start-Signal warten
      S_L_DONE: begin
        ready   = 1'b1;
        geh_auf = (kmac_out == response_reg);
        if (!start)
          next_state = S_IDLE;
      end

      // -------------------------------------------------
      // SCHLÜSSEL
      // -------------------------------------------------
      // 1) Auf Challenge vom Schloss warten
      S_K_WAIT_CHALLENGE: begin
        if (challenge_in_valid)
          next_state = S_K_KMAC_START;
      end

      // 2) KMAC mit Challenge_reg || k starten
      S_K_KMAC_START: begin
        kmac_start = 1'b1;
        next_state = S_K_KMAC_WAIT;
      end

      // 3) Auf KMAC-Fertig warten
      S_K_KMAC_WAIT: begin
        kmac_start = 1'b1;
        if (kmac_done)
          next_state = S_K_SEND_RESPONSE;
      end

      // 4) Response (Tag) an Schloss senden
      S_K_SEND_RESPONSE: begin
        response_out_valid = 1'b1;    // kmac_out ist gültige Antwort
        ready              = 1'b1;
        next_state         = S_K_DONE;
      end

      // 5) Fertig, auf neues Start-Signal warten
      S_K_DONE: begin
        ready = 1'b1;
        if (!start)
          next_state = S_IDLE;
      end

      default: begin
        next_state = S_IDLE;
      end
    endcase
  end

endmodule
