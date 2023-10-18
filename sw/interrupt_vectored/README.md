# interrupt_vectored

Test the interrupts from peripherals

## Description

Simple code to test if ECALL, EBREAK and hardware interrupts work.
This version uses mtvec vectored mode.

The External Timer interrupt is set to 1000 Hz.
The TIMER1 interrupt is set to 100 Hz.
The TIMER2 interrupt is set to 1 Hz
SPI1 and I2C1 interrupts are triggered once in 10 sec, by executing a transmit action
The UART1 receive interrupt is also active.
Button `KEY3` of the DE0-CV board is connected to the external input interrupt.

## Status

Works on the DE0-CV board.
