# ASCON ASIC Implementation

This repository contains both ASIC and FPGA implementations of the ASCON cryptographic hash function, designed according to the NIST Lightweight Cryptography standard [NIST SP 800-208](https://doi.org/10.6028/NIST.SP.800-208). The project implements ASCON-HASH with a 256-bit output combined with a UART controler.

## Project Structure

### ASIC Implementation (`asic/`)
The ASIC folder contains Verilog files specifically designed for the OpenROAD flow using I/O pads for chip-level implementation.

### FPGA Implementation (`fpga/`)
The FPGA folder features the FPGA implementation designed for the ULX3S board, utilizing hardware GPIO pins for functional testing purposes. This implementation serves as a validation platform for the ASCON algorithm before ASIC tape-out. More details are available in the [FPGA README](fpga/README.md). This folder contains the latest Yosis logs and the ULX3S FPGA bit file.

## ASCON-HASH Architecture

The implementation follows the ASCON-HASH specification with a 256-bit output as defined in the NIST Lightweight Cryptography standard.
![ASCON Module Architecture](img/ascon_module.drawio(3).png)

### Core Modules

#### 1. State Machine Top (`ascon_state_machine_top.sv`)
The central module of the ASCON-HASH core that instantiates and connects the state machine with the permutation module, managing the data flow between them according to the current state.

#### 2. ASCON State Machine (`ascon_state_machine.sv`)
Implements the main control logic for the ASCON hash algorithm with the following states:
- **INIT**: Initialize all registers and prepare for hashing
- **IDLE**: Load initialization vector (IV) into state registers
- **ABSORB**: Process input message blocks
- **PERMUTE**: Execute 12 cryptographic permutation rounds
- **SQUEEZE**: Extract final hash output

![State Machine Flow](img/state%20machine.drawio.png)

#### 3. ASCON Permutation Module (`ascon_permutation.sv`)
Contains the core cryptographic permutation function that implements:
- 12 rounds of ASCON permutation - one each clk cycle
- round constants (lookup table)
- Substitution box (5 Bit S-box) operating parallel on all 64 5-Bit words 
- Linear diffusion layer with rotation operations

#### 4. ASCON Top Module (`ascon_top.sv`)
The top-level integration module that connects the ASCON-HASH core and adds the UART controller implementation. This module handles:
- Clock domain management
- UART communication for input/output
- Control signal coordination between the core and external interfaces
- Integration of the ASCON core with communication peripherals

#### 5. Complete ASCON ASIC Design
The UART controller combined with the ASCON hash core results in the complete ASCON ASIC design. The UART module (`uart.sv`) provides UART RX and TX instances. [Nandland UART](http://www.nandland.com/vhdl/modules/module-uart-serial-port-rtl.html).

![ASCON Complete Architecture](img/ascon_complete.drawio(2).png)

## ASCON-HASH Algorithm Implementation

This implementation is fully compliant with:
- [NIST SP 800-208: Status Report on the Third Round of the NIST Lightweight Cryptography Standardization Process](https://doi.org/10.6028/NIST.SP.800-208)

- **Hash Output Size**: 256 bits
- **State Size**: 320 bits (5 × 64-bit words)
- **Permutation Rounds**: 
  - 12 rounds (p^a) during initialization and finalization
- **Rate**: 64 bits per absorption cycle (expected to be already permuted)

## Getting Started

For FPGA implementation and testing, refer to the detailed instructions in the [FPGA README](fpga/README.md).

For ASIC implementation, the files in the `asic/` directory are ready for integration into OpenROAD or other ASIC design flows.

## License

This project implements the ASCON algorithm as specified in the NIST standard and is intended for research and educational purposes.
