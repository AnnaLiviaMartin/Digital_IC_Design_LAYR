# KMAC Cocotb + iCE40 Makefile (deine 9 Module!)
TOPLEVEL_LANG     = verilog   # .sv als Verilog (icarus-kompatibel!)
VERILOG_SOURCES   = $(wildcard *.sv)
SIM               = icarus
PLUSARGS          = --vcd=tb.vcd

# Default: pad10_1 Test
TOPLEVEL          = pad10_1
MODULE            = test_pad10_1

include $(shell cocotb-config --makefiles)/Makefile.sim

# Spezifische Tests (deine Module)
pad10_1:
	make sim TOPLEVEL=pad10_1 MODULE=test_pad10_1

enc8:
	make sim TOPLEVEL=enc8 MODULE=enc8Test

keccak:
	make sim TOPLEVEL=Keccak MODULE=KeccakTest

bytepad:
	make sim TOPLEVEL=bytepad MODULE=bytepadTest

right_encode:
	make sim TOPLEVEL=right_encode MODULE=right_encodeTest

encode_string:
	make sim TOPLEVEL=encode_string MODULE=encode_stringTest

kmac_statemachine:
	make sim TOPLEVEL=KMACStatemachine MODULE=KMACStatemachineTest

# Alle Tests auf einmal
all:
	pytest *_Test.py *_test.py -v

# Waveform Viewer
view:
	gtkwave tb.vcd &

# Yosys Synthesis (SV Mode!)
synth:
	yosys -p "read_verilog -sv *.sv; synth_ice40 -top pad10_1 -json pad.json"

synth-all:
	for mod in pad10_1 enc8 Keccak bytepad right_encode; do \
		echo "=== $$mod ==="; \
		yosys -p "read_verilog -sv *.sv; synth_ice40 -top $$mod -json $$mod.json"; \
	done

# iCE40 FPGA Flow
pnr:
	nextpnr-ice40 --hx1k --json pad.json --pcf ice40.pcf --asc pad.asc

bitstream: synth pnr
	icepack pad.asc pad.bin

upload: bitstream
	iceprog pad.bin

# Clean (nutzt cocotb's clean::)
clean::
	@echo "Clean completed"

.PHONY: pad10_1 enc8 keccak bytepad right_encode encode_string kmac_statemachine all view synth synth-all pnr bitstream upload clean
