# gamma

Test a mathematical function.

## Description

This program can be used to test a math library function
with one parameter, like sin, cos, gamma, exp.
The program uses the `clock` function to time the function.
The time shown is in microseconds, only for the calculations,
not for the UART functions.

Note that this program must be linked with `-u _printf_float`

## Status

Works on the board.
