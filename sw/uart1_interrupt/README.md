# uart1_interrupt

Test UART1 transmit and receive interrupts

## Description

This program tests if the UART1 transmit and receive interrupt
work as expected. When the program starts, type some data
on the keyboard and the receive interrupt will collect the
characters. When the buffer is full or an enter key is pressed,
the receive interrupt will be disabled and the transmit interrupt
will send the characters to the terminal.

During reception and transmission, led 0 and 1 will flash.

Note that the UART1 has only one interrupt. The BREAK interrupt
is not tested.

## Status

Works on the board. You need a Serial to USB device
and a terminal program like Putty.
