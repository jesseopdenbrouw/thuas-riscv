
# DE0-CV extra ROM files

This is an implementation of the ROM using Altera's `altsyncram` megafunction.
When using this megafunction in combination with on-chip debugging and/or
bootloader, only one copy of altsyncram for the ROM will be the instantiated.
The device agnostic standard VHDL code for the ROM will make two copies of
the altsyncram, because of limitations of the synthesizer.

## How to use

* Copy `mem_altera.vhd` over `mem.vhd` in the `rtl` directory.
* Copy `rom_image.mif` to the `rtl` directory.
* Copy `bootrom_image.mif` to the `rtl` directory.
* In the `rtl` directory, update the file `riscv.vhd` to use the MIF files. Look at the point of instantiation and update the generic `MEMORY_FILE` accordingly.

When starting simulation from Quartus, the MIF files are
copied to the simulation directory.

When using Questasim or Modelsim Altera Starter Edition, simulation
of the altsyncram is possible.

Also works on the DE10-Lite board.

