# spi1readeeprom

This program reads the first 16 bytes from a 25AA010A 128-bytes EEPROM.

## Description

The address is printed, as is the content of the byte, in hexadecimal.

Also the ASCII character is printed, if printable.

The program uses a hardware NSS (Chip Select) signal. Because of this,
a 24-bit instruction code is written to the EEPROM. The first byte is
the command (0x03, READ). The next byte is the address and the last
byte is a dummy 0x00. During the transfer, data is read from the EEPROM.
The first two bytes are dummies, the last byte is the data from the 
address inside the EEPROM. Only the least significant byte of the received
24 bits is of interest.

## Status

Works on the DE0-CV board. You need a 25AA010A EEPROM.
