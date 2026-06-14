
# DE10-Lite Board

The DE10-Lite board has a clock oscillator with a period of 20 ns (50 MHz).

In this directory, three files are present:

* `de10_lite.vhd`: board top-level file.
* `de10-lite.qpf`: Quartus project file.
* `de10-lite.qsf`: Quartus settings file.

Please complete the following steps:

* Copy all design VHDL files, including the testbenc files, except the DE0-CV top level file, into this directory.
* Start Quartus by clicking on the QPF-file.
* Synthesize the design.

The fabric of the MAX10 devices is slower than that of the Cyclone V devices, so the Fmax is lower.

Note the following:

* The pin assignments can be viewed in the Pin Planner.
* The on-print ADXL345 G-sensor is connected to the I2C2 peripheral.
* This design has two extra outputs: `O_GSENSOR_CS_n` (output high, so I2C) and `O_GSENSOR_SDO` (output low, so the device has address 0x53). These are necessary for correct usage of the on-print G-sensor.
* The pinout of the peripherals is the same as for the DE0-CV board, except for I2C2.
* Push button 0 (KEY0) is connected to the reset.
* No pins are connected to the Arduino headers.
* The ADC is not used.
* Quartus reports that the core registers suffer from undefined read-during-write behavior, but we ran some programs and didn't find any problems.

