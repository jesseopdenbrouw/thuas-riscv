# Software programs for the THUAS RISC-V processor

This directory contains some sample software programs
to be run on the THUAS RISC-V 32-bit processor as can be
found in the hardware directory.

Examples include some basic function testing, usable
in simulation and more sophisticated examples (such
as interrupt handling) that run on the DE0-CV board.

We make extensive use of the volatile keyword to emit
variables to the RAM instead of keeping them in
registers, for easy inspection in a simulator.

Programs are translated by the RISC-V GNU C/C++ compiler.

Executables are in ELF format, and are converted to
S-record format, which can be uploaded with the `upload`
program (when the bootloader is installed). S-record
files are converted to a VHDL-suitable ROM table for
inclusion in the processor hardware. See the documentation.

Build the complete set of examples by starting `make` on
the command line. Make sure that the RISC-V C/C++ compiler
is in the PATH environment variable.

