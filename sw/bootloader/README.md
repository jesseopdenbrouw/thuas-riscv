# THUAS RISC-V simple bootloader

Simple bootloader for the THUAS RISC-V microcontroller
on a FPGA.

## Description

The bootloader is loaded at address 0x10000000 of the
address space and is executed at startup. It waits for
about 5 seconds (@ 50 MHz) before it jumps to the
application at address 0x00000000. If a character is
received via the USART within these 5 seconds, a
prompt is shown and the user can enter commands. The
command "r" (without the quotes) starts the main
application.

An S-record file can be uploaded using the `upload`
program. If the bootloader is contacted within the
5 second grace period, the S-record file is uploaded
to the ROM (or RAM, but programs can only be started
from ROM). Do not use any terminal program (e.g. Putty)
when uploading.

The bootloader program has its own linker file because
the bootloader starts at address 0x10000000.

## Status

Works on the board. The bootloader must be installed in the hardware.
