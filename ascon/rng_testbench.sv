module testbench;
  reg clk;
  reg reset;
  wire [127:0] random_number_out; 

  // Instanzierung deines Designs
  rng random_number_generator (
    .clk(clk),
    .reset(reset),
    .random_number_out(random_number_out)
  );

  initial begin
    // Signalinitialisierung
    clk = 0;
    reset = 1;
    #10 reset = 0;

    // Warten für den gewünschten Zeitpunkt
    #100; // Wartezeit entsprechend deiner Simulation

    // Simulation beenden
    $finish;
  end

  always #5 clk = ~clk; // Taktsignal

  // Wellenformdatei für GTKWave erstellen
  initial begin
    $dumpfile("output.vcd");
    $dumpvars(0, testbench);
  end

  initial begin
    // .... vorhandener Code ....
    #100; // Wartezeit bis zum Auslesen 
    $display("Random Number Output: %h", random_number_out);
    // Simulation beenden
    $finish;
  end

endmodule
