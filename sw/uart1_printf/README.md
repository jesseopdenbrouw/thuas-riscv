# uart1_printf

Print using `printf`

## Description

Simple program to print an integer, a pointer, a float
and a double to the terminal using `printf` and the UART1.

This example uses the `printf` C library function, which in
turn uses the `_read` and `_write` system calls. These system
calls are handled by stubs (so no ECALL is used). The user
has to implement the `__io_getchar.c` and ` __io_putchar.c`
functions to transmit and receive a single character.

## Status

Works on the board. You need a Serial to USB device
and a terminal program like Putty.
