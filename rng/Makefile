VERILOG_PRNG = prng.sv
VERILOG_TRNG = trng.sv

VERILOG_PRNG_OUTPUT = prng_synth.sv
VERILOG_TRNG_OUTPUT = trng_synth.sv

.PHONY: all synth clean

all: synth synth2

synth: $(VERILOG_PRNG)
	yosys -p "read_verilog -sv $(VERILOG_PRNG); write_verilog $(VERILOG_PRNG_OUTPUT)"

synth2: $(VERILOG_TRNG)
	yosys -p "read_verilog -sv $(VERILOG_TRNG); write_verilog $(VERILOG_TRNG_OUTPUT)"

test: $(VERILOG_PRNG) $(VERILOG_TRNG)
	python3 test.py

clean:
	rm $(VERILOG_PRNG_OUTPUT) $(VERILOG_TRNG_OUTPUT)
