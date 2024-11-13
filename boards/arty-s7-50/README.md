
# Arty S7/50 Board

The Arty S7/50 board has a clock oscillator with a period of 10 ns (100 MHz).

In this directory, two files are present:

* `arty_s7_50_board.vhd`: board top-level file.

* `arty_s7_50_board.xdc`: XDC file.

Please complete the following steps:

* Create a new Vivado project with a sensible name.

* During creation, add all VHDL file from the `rtl` directory (execpt testbenches and the DE0-CV top level file). Make sure to **copy** the files.

* Add the board top-level file. Make sure to **copy** the file.

* Add the XDC file to the constraints directory. Make sure to **copy** the file.

* A default synthesis and implementation are provided at creation time.

* Synthesize the design.

In the XDC file, the clock period is set to 8 ns (125 MHz). This makes sure the actual clock period will be less than 10 ns. You can add a new synthesis/implementation with increased performance to get a better clock period.

We find good speed results when the implementation is set to Default and the implementation is set to Performance+Explore.

Note that not all GPIOA pins (in and out) are connected to physical FPGA pins.
