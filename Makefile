VERILOG_SRC = led_spi_test.sv
TOP_MODULE = ButtonLED
LPF_FILE = constraint.lpf

JSON_FILE = button.json
ASC_FILE = button.asc
BIT_FILE = button.bit

OUT_FILE = buttonLed.out

.PHONY: all synth program clean

all: synth place pack# program

synth: $(VERILOG_SRC)
	yosys -p "read_verilog -sv $(VERILOG_SRC); synth_ecp5 -top $(TOP_MODULE) -json $(JSON_FILE)"

place: $(JSON_FILE)
	nextpnr-ecp5 --85k --package CABGA381 --lpf $(LPF_FILE) --json $(JSON_FILE) --top ButtonLED --textcfg $(OUT_FILE)

pack: $(OUT_FILE)
	ecppack --compress $(ASC_FILE) $(BIT_FILE)

#program: $(BIT_FILE)
#	iceprog $(BIT_FILE)

clean:
	rm -f $(JSON_FILE) $(ASC_FILE) $(BIT_FILE)
