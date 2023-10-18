# interrupt_direct

Test the interrupt from peripherals.

## Description

Simple code to test if ECALL, EBREAK and hardware interrupts work.
This version uses `mtvec` direct mode.

The External Timer interrupt is set to 10 Hz.
The TIMER1 interrupt is set to 2 Hz.
The TIMER2 interrupt is set to 1 Hz
The SPI1 and I2C1 devices transmit at 10 sec interval, generating an interrupt
The UART1 receive interrupt is also active.
Button `KEY3` of the DE0-CV board is connected to the external input interrupt.

## Status

Works on the board.
