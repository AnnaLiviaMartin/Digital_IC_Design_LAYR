module Counter #(
    parameter integer WIDTH = 22 //count to 2^WIDTH
)(
    input logic clk,
    output logic [3:0] gleds,
    output logic rled     
);

    logic [WIDTH-1:0] val = 0;
    logic [3:0] val2;
    logic [0:0] val3 = 0;
    logic [31:0] counter2 = 0;

    logic [0:0] fail = 0;
    logic [0:0] test = 0;
    logic [0:0] test2 = 0;

    localparam a = 16'h5DEE; // Beispielwerte
    localparam c = 16'hB;          // Beispielwerte
    localparam m = 2'd2;      // 2^16
    logic [15:0] state = 16'h1234;
    logic rng_output;

    logic x1;
    logic x2;
    /*logic r_bit = 1;
    logic a = 0;
    logic b = 1;
    logic c = 0;
    logic d = 1;*/

    //rng rng_inst (
    //    .clk(clk),
    //    .bit_out(rng_output)
    //);

    /*

    logic p1 [0:0];
    logic p2 [0:0];
    logic p3 [0:0];
    logic p4 [0:0];

    rng rng_inst (
        .clk(clk),
        .a(1),
        .b(1),
        .bit_out(rng_output)
    );

    rng rng_inst2 (
        .clk(clk),
        .a(1),
        .b(1),
        .bit_out(p1[0])
    );

        rng rng_inst3 (
        .clk(clk),
        .a(1),
        .b(1),
        .bit_out(p2[0])
    );

        rng rng_inst4 (
        .clk(clk),
        .a(1),
        .b(1),
        .bit_out(p3[0])
    );

    rng rng_inst5 (
        .clk(clk),
        .a(1),
        .b(1),
        .bit_out(p4[0])
    );

    */

    always_ff@(posedge clk) begin
        if (val == 0) begin
            //val2 <= ~val2;
            // val2 <= {counter2 % 2 == 0 ? 1 : 0, counter2 % 3 == 0 ? 1 : 0, counter2 % 4 == 0 ? 1 : 0, counter2 % 5 == 0 ? 1 : 0};
            //val2 <= counter2 % 2;
            //rled <= rng_output;
            rled <= ~rled;
            //rled <= state;
            //val2 <= counter2[3:0];
            // val2 <= counter2 % 16;
            //rled <= ~rled;
            //rled <= random;
            val2 <= (counter2 % 2 == 0) ? 15 : 0;
        end
        val++;
        counter2 <= counter2 + val / 2;
        //state <= (a * state + c) % m;
        //if (counter2 == 0)
        //    val2 <= val % 16;
        //counter2++;
        /*
        val++;
        //if (val3 == 1)
        //    fail <= 1;
        if (val == 0 && val3 == 0 && !fail)
            //val <= {val3, val3, val3, val3};
            val2 <= ~val2[3:0];*/
    end

    always_ff@(posedge clk) begin
        // random <= ~random;
    end

    always_comb begin
        // val3 <= ~val3;
        // a = b;
        // a = c;
        /// c = a;
        // d = a;
        // gleds = {a, b, c, d};
        // gleds <= $random ^ val [WIDTH-1 : WIDTH-4];
        // gleds <= ~gleds;
        // gleds <= val [WIDTH-1 : WIDTH-4];
        gleds <= val2;
    end

endmodule
