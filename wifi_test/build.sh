#!/bin/bash
set -e

yosys -q -p "
    read_verilog -sv led_spi_test.sv;
    synth_ecp5 -top ButtonLED -json design.json
"

nextpnr-lfe5u --25f --package CABGA381 --speed 6 \
              --json design.json \
              --lpf constraints.lpf \
              --textcfg design.cfg

ecppack --bit --input design.cfg top.bit

echo "✓ top.bit ready!"

