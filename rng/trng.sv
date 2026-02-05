`timescale 1ns/1ps

module trng (
    output logic random
);

    (* keep = "true" *) logic [4:0] q;

    assign q[0] = ~q[4] ^ q[0];
    assign q[1] = ~q[0];
    assign q[2] = ~q[1];
    assign q[3] = ~q[2] ^ q[0];
    assign q[4] = ~q[3];

    assign random = q[4];

endmodule
