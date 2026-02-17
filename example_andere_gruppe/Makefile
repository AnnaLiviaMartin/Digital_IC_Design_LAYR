TOP = Counter 
OUT = ulx3s_rc522_min

DEVICE  = 85k
PACKAGE = CABGA381
FREQ    = 25
LPF     = constraint.lpf

RTL = \
  Counter.sv

all: $(OUT).bit

$(OUT).json: $(RTL)
    yosys -p "read_verilog -sv $(RTL); synth_ecp5 -top $(TOP) -json $@"

$(OUT).config: $(OUT).json $(LPF)
    nextpnr-ecp5 --$(DEVICE) --package $(PACKAGE) \
        --json $(OUT).json --lpf $(LPF) --textcfg $@ --freq $(FREQ)

$(OUT).bit: $(OUT).config
    ecppack --compress $< $@

prog: $(OUT).bit
    sudo fujprog $<

clean:
    rm -f *.json *.config *.bit

.PHONY: all clean prog