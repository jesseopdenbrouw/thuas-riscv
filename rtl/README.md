# Hardware

This directory contains the hardware description of the
THUAS RISC-V RV32IM Zicsr Zicntr Zicond Zihpm Zba Zbs
Sdext Sdtrig 32-bit processor.


## thuas-riscv

This is a version of the three-stage pipelined processor
and incorporates a hardcoded bootloader and on-chip debugger.
The bootloader is located at address 0x10000000. The bootloader
is able to load an S-record file into the ROM at address
0x00000000 using the `upload` program. The on-chip debugger
is compatible with OpenOCD and GDB.

## Bootloader

When the processor starts, the bootloader waits for about
5 seconds for a keboard press (using the UART). If not
within this 5 seconds, the bootloader starts the main
program at address 0x00000000. If pressed, the bootloader
enters a simple monitor program. Type 'h' for help.

An S-record file can be uploaded by the `upload` program.
If `upload` contacts the bootloader within the 5 second
delay, the S-record file is transmitted to the processor
and the instructions are placed in the ROM. Make
sure that NO terminal connection (e.g. Putty) is active.

The registers may be optionally placed in FPGA flip-flops.
This will speed up the design a little bit but also uses
about 1000 extra flip-flops.

## On-chip Debugger
The on-chip debugger is compatible with the RISC-V Debug
Specification 1.0.0-rc3. It supports OpenOCD and GDB.
Eclipse-CDT is supported.


## Status
This version runs without any modification directly on
the Terasic DE0-CV board.
