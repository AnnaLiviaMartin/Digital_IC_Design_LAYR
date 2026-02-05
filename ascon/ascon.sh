#!/bin/bash
yosys -p "read_verilog -sv ascon.sv; synth -top ascon; write_verilog ascon_synth.sv"
