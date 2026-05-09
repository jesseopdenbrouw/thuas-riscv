
# DE0-CV extra ROM files

This is an implementation of the ROM using Altera's `altsyncram` megafunction.
When using this megafunction in combination with on-chip debugging and/or
bootloader, only one copy of altsyncram will be the instantiated. The
device agnostic standard VHDL code for the ROM will make two copies of
the altsyncram, because of limitations of the synthesizer.

## How to use

* Copy `rom_altera.vhd` over `rom.vhd` in the `rtl` directory.
* Copy `rom_image.mif` to the `rtl` directory.

When starting simulation from Quartus, the `rom_image.mif` file is
copied to the simulation directory.

When using Questsim or Modelsim Altera Starter Edition, simulation
of the altsyncram is possible.

Also works on the DE10-Lite board.

