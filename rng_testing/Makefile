VERILOG_SRC = Counter.sv
VERILOG_SRC_RNG = Rng.sv
TOP_MODULE = Counter
PCF_FILE = counter.pcf

JSON_FILE = counter.json
BLIF_FILE = counter.blif
ASC_FILE = counter.asc
BIT_FILE = counter.bit

.PHONY: all synth program clean

all: synth place pack program

synth: $(VERILOG_SRC)
	yosys -p "read_verilog -sv $(VERILOG_SRC); read_verilog -sv $(VERILOG_SRC_RNG); synth_ice40 -top $(TOP_MODULE) -json $(JSON_FILE) -blif $(BLIF_FILE)"

place: $(JSON_FILE)
	nextpnr-ice40 --package tq144 --pcf $(PCF_FILE) --lp1k --json $(JSON_FILE) --asc $(ASC_FILE)

pack: $(ASC_FILE)
	icepack $(ASC_FILE) $(BIT_FILE)

program: $(BIT_FILE)
	iceprog $(BIT_FILE)

clean:
	rm -f $(JSON_FILE) $(BLIF_FILE) $(ASC_FILE) $(BIT_FILE)
