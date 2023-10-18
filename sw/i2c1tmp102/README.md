
# i2c1tmp102

Read temperature from a TMP102 sensor.

## Description

This program reads raw temperature data from a TMP102
digital temperature sensor on the I2C1 bus. Address is
0x48. If slave is found, the temperature high and low
bytes are read and printed on the terminal. Conversion
to a real temperature (in degree Celsius) must be
handled in software. Tested with a Sparkfun TMP102
breakout board.

The transmission speed may be set to 100 kbps for Standard
mode or 400 kbps for Fast mode.

## Status

Works on the board
