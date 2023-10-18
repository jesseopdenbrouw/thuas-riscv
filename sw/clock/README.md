# Clock

Simple clock that counts from the last reset.

## Description

This program uses the `gettimeofday` function call,
The clock is implemented via the CSR registers
TIME and TIMEH. It needs the UART1 to transmit
data.

Note: only the lower 32 bits of TIMEH:TIME is used,
so the count number rolls over every 4295 seconds.

## Status

Works on the board.
