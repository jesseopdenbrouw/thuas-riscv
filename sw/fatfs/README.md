# fatfs

Implementation of FATFS for THUAS RISC-V processor

## Description

This is a implementation of the FATFS library found at
[http://elm-chan.org/fsw/ff/00index_e.html](http://elm-chan.org/fsw/ff/00index_e.html).

The implementation currently supports:

* SD card: tested with 32 GB SDHC card
* Long filename support
* Codepage 437 (US)

Create a file called `read.txt` on the SD card. This program
will read the ASCII characters and print them on the terminal.
After that, the program will create and write a file
called `write.txt`.

## status

Works on the DE0-CV board
