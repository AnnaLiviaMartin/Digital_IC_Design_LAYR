yosys -p "read_verilog -sv Counter.sv; synth_ice40 -top Counter -json counter.json -blif counter.blif"
# sg48
#nextpnr-ice40 --package sg48 --pcf counter.pcf --up5k --json counter.json --asc counter.asc
nextpnr-ice40 --package bga256 --pcf counter.pcf --up5k --json counter.json --asc counter.asc
icepack counter.asc counter.bit
iceprog counter.bit

