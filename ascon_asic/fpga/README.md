# ASCON FPGA Implementation

This repository contains an FPGA implementation of the ASCON cryptographic algorithm, designed for the ULX3S FPGA board.

## Overview

This implementation uses the ULX3S FPGA board to test the ASCON cryptographic hash function through hardware-based UART communication. The design allows for real-time testing and validation of the ASCON algorithm on dedicated hardware.
## Hardware Setup

You need to connect to the USB1 (US1) connector to program the ULX3S board.

## Prerequisites

- Yosys and NextPNR toolchain installed
- fujprog programmer available in system PATH

For toolchain installation instructions, see the [ULX3S manual](https://github.com/emard/ulx3s/blob/master/doc/MANUAL.md#precompiled-opensource-tools-for-all-platforms).

## Building and Programming

To build the bitstream and program the FPGA:

```bash
make clean
make ulx3s.bit
sudo fujprog ulx3s.bit
```

The Makefile is configured for the ULX3S 85F variant by default.

## Testing and Validation

The ASCON implementation is tested using UART communication between the FPGA and a host computer. The firmware and test scripts are not part of this repository. The testing setup consists of:

- **FPGA Implementation**: The ULX3S board runs the ASCON hardware implementation and communicates via UART
- **Test Controller**: A Nucleo board sends permuted 64 messages to the FPGA for hashing including the signals: core_reset_n_phy and core_msg_last_phy using GPIOs
- **Host Verification**: A Python script on the host computer compares FPGA-generated hashes with a reference Python implementation

### Test Results

Extensive testing was performed using random messages of varying lengths, covering all edge cases of the ASCON algorithm. The results show:

- **Overall Stability**: The implementation produces stable and correct results
- **Error Rate**: Less than 1% of hash comparisons initially failed
- **Error Resolution**: All failed comparisons succeeded on the second attempt
- **Error Source**: Analysis revealed that errors were due to UART communication signal issues

This validates that the FPGA implementation of ASCON is functionally correct, with any observed errors being attributed to communication layer issues rather than cryptographic computation errors.

