# spi1speed

This program reads the first 16 bytes from an 25AA010A 128-bytes EEPROM

## Description

The data is printed as an ASCII string, with the last byte a 0x00.
Make sure the data are valid ASCII printable characters.

This program is used to test the SPI1 device at full speed.

The program uses a hardware triggered NSS (Chip Select) signal. Because of this,
a 24-bit instruction code is written to the EEPROM. The first byte is
the command (0x03, READ). The next byte is the address and the last
byte is a dummy 0x00. During the transfer, data is read from the EEPROM.
The first two bytes are dummies, the last byte is the data from the 
address from the EEPROM. Only the least significant byte is of
interest.

## Status

Works on the board
