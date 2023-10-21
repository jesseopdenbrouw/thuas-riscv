# timer1

Test TIMER1 peripheral.

## Description

This program test the TIMER1 interrupt function.
The interrupt frequency is set to 1 Hz. In the trap
handler, the pins at POUT pins 15 and 2 are toggled.
In the default DE0-CV setup, pin 2 is connected to
a led and pin 15 is connected to a GPIO connector.

## Status

Works on the board.
