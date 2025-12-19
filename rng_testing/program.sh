yosys -p "read_verilog -sv Counter.sv; synth_ice40 -top Counter -json counter.json -blif counter.blif"
nextpnr-ice40 --package tq144 --pcf counter.pcf --lp1k --json counter.json --asc counter.asc
icepack counter.asc counter.bit
iceprog counter.bit

