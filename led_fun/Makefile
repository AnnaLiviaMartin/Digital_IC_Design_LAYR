VERILOG_SRC = led_fun.sv
TOP_MODULE = led_fun
PCF_FILE = leds.pcf

JSON_FILE = led_fun.json
BLIF_FILE = led_fun.blif
ASC_FILE = led_fun.asc
BIT_FILE = led_fun.bit

.PHONY: all synth program clean

all: synth place pack program

synth: $(VERILOG_SRC)
	yosys -p "read_verilog -sv $(VERILOG_SRC); synth_ice40 -top $(TOP_MODULE) -json $(JSON_FILE) -blif $(BLIF_FILE)"

place: $(JSON_FILE)
	nextpnr-ice40 --package tq144 --pcf $(PCF_FILE) --lp1k --json $(JSON_FILE) --asc $(ASC_FILE)

pack: $(ASC_FILE)
	icepack $(ASC_FILE) $(BIT_FILE)

program: $(BIT_FILE)
	iceprog $(BIT_FILE)

clean:
	rm -f $(JSON_FILE) $(BLIF_FILE) $(ASC_FILE) $(BIT_FILE)
