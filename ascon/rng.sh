#!/bin/bash
yosys -p "read_verilog -sv rng.sv; synth -top rng; write_verilog rng_synth.sv"
