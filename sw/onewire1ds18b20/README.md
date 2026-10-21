# onewire1ds18b20.vhd

Read the temperature of the 1-Wire DS18B20 device

## Description

The DS18B20 uses the 1-Wire protocol to communicate. It
measures the temperature in 1/16th degree Celsius.

See: https://www.analog.com/media/en/technical-documentation/data-sheets/ds18b20.pdf

The 1-Wire peripheral is very simple. It can mange only one slave device at the time.
There is no provision for bus enumeration (Search ROM).

## Status

Works on the board.
