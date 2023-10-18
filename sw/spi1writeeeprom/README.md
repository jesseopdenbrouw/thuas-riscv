# spi1writeeeprom

This program writes a maximum of 16 bytes to an 25AA010A 128-bytes EEPROM

## Description

This program writes a maximum of 16 bytes to an 25AA010A 128-bytes EEPROM
After that, the Status Register is constantly read to check if the
write is completed. After that, 16 bytes are read from the EEPROM.
The address is printed, as is the content of the byte, in hexadecimal.


The program uses a software triggered NSS (Chip Select) signal, connected to
POUTA pin 15.

## Status

Works on the board.
