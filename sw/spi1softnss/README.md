# spi1softnss

This program reads the first 16 bytes from an 25AA010A 128-bytes EEPROM

## Description

The address is printed, as is the content of the byte, in hexadecimal

Also the ASCII character is printed, if printable

The program uses a software triggered NSS (Chip Select) signal, connected to
POUTA pin 15. First, an 8-bit EEPROMREAD code is send. Data is received,
but is discarded. Then an 8-bit address is send, and the received data
is discarded. Last, an 8-bit dummy (0x00) is send. During the
sending of the dummy, the 25AA010A transmits the contents of the
address, and this value is printed to the USART.

## Status

Works on the board
