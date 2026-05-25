# DE23-Lite Board

This directory contains a complete version of the SoC for the
DE23-Lite board.

Please note the following:

* You need the Quartus Pro version of the software (tested with 26.1).
* The project includes a reset IP and a PLL IP (a reset IP is mandatory).
* The SoC is clocked at 150 MHz from the PLL.
* The reset is connected to push-button KEY0.

The pinout of the peripherals on GPIO_0 is the same as with the DE0-CV board,
except for I2C2 which is connected to the on-print ADC and HDMI chips and
UART1 is connected to the on-board FTDI chip. Look for /dev/ttyUSB0 under Linux.
