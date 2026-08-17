
# DE0-CV extra memory files

This is an implementation of the memory using Altera's `altsyncram` megafunction.
It can be used to instantiate True Dual-port RAM (or writable ROM).
When using this megafunction in combination with on-chip debugging and/or
bootloader, only one copy of altsyncram for the memory will be the instantiated.
The device agnostic standard VHDL code for the memory will make two copies of
the altsyncram, because of limitations of the synthesizer.

## How to use

* Copy `mem_altera.vhd` over `mem.vhd` in the `rtl` directory.
* Copy `rom_image.mif` to the `rtl` directory.
* Copy `bootrom_image.mif` to the `rtl` directory.
* In the `rtl` directory, update the file `riscv.vhd` to use the MIF files. Look at the point of instantiation and update the generic `MEMORY_FILE` accordingly.

When using Questasim or Modelsim Altera Starter Edition, simulation
of the altsyncram is possible.

It _is_ possible the show the contents of the altsyncram, but that is not straightforward. You have to find the memory array of the altsyncram. Try the Questasim command `mem list -r`.

Also works on the DE10-Lite board.

