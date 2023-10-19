
# Cmos S7/25 Board

The Cmod S7/25 board has a clock oscillator of 83.333 ns (12 MHz). Use a MMCM to get 10 ns (100 MHz).

In this directory, two files are present:

* `cmod_s7_25_board.vhd`: board top-level file.

* `cmod_s7_25.xdc`: XDC file.

Please complete the following steps:

* Create a new Vivado project with a sensible name.

* During creation, add all VHDL file from the `rtl` directory (execpt testbenches and the DE0-CV top level file). Make sure to **copy** the files.

* Add the board top-level file. Make sure to **copy** the file.

* Add the XDC file to the constraints directory. Make sure to **copy** the file.

* A default synthesis and implementation are provided at creation time.

* Synthesize the design.

In the XDC file, the clock period is set to 8 ns (125 MHz). This makes sure the actual clock period will be less than 10 ns. You can add a new synthesis/implementation with increased performance to get a better clock period.
