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

## Support for Windows tools

There is support for Windows tools. `srec2vhdl` and
`upload` can be build with GCC MinGW and Visual Studio.
For building the RISC-V programs, a RISC-V GNU GCC compiler
is needed.

Best is to use a precompiled compiler for Windows and
build tools (make, rm, mkdir etc.). Please have a look
at [xPack RISC-V Toolchain](https://xpack.github.io/dev-tools/riscv-none-elf-gcc/)
and [Windows build tools](https://xpack.github.io/dev-tools/windows-build-tools/).
For building `srec2vhdl` and `upload`, you need a GCC native compiler. Have a look
at [The xPack GNU Compiler Collection (GCC)](https://xpack.github.io/dev-tools/gcc/).

