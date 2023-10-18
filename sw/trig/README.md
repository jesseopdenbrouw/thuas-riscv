# trig

Test some trigoniometry functions.

## Description

Some trigonometry function tests from the mathematical library.
Uses the UART to print data to a terminal. Note that this is
a big binary.

The program uses the `clock` function to time the functions.
The time shown in in microseconds, only for the calculations,
not for the UART functions.

Note that this program must be linked with `-u _printf_float`

## Status

Works on the board.
