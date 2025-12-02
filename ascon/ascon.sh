#!/bin/bash
yosys -p "read_verilog -sv ascon.sv; synth -top ascon; write_verilog ascon_synth.sv"

# yosys -p "read_verilog -sv p1.v; synth_ice40 -top p1; write_verilog p1_synth.v; write_json synth.json" -o p1_synth.json
# yosys -f p1.tcl
# yosys -p "read_verilog -sv p1.v; synth -top p1; plugin -i write_vcd; write_vcd -o p1.vcd"
# yosys -p "read_verilog -sv p1.v; hierarchy -top p1; synth -top p1; write_verilog -noattr p1_synth.v; write_blif p1.blif; write_dot -hierarchy p1.dot"



