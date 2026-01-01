# interrupt_vectored

Test the interrupts from peripherals

## Description

Simple code to test if ECALL, EBREAK and hardware interrupts work.
This version uses mtvec vectored mode.

* The External Timer interrupt is set to 1000 Hz.
* The TIMER1 interrupt is set to 100 Hz.
* The TIMER2 interrupt is set to 1 Hz.
* SPI1, I2C1, I2C2 and MSI interrupts are triggered once in 10 sec,.
* The UART1 receive interrupt is also active.
* Button `KEY3` of the DE0-CV board is connected to the external input interrupt.

Use the macro USEPRINTF to use `printf` instead of `uart_puts`.

## Note

When using `printf` the interrupts are processed really slow, especially TIMER1 and the external timer.
This is because `printf` uses the `write` system call that in turn uses blocking `uart_putc` to transmit characters, i.e. stalling in the trap handler.

## Status

Works on the DE0-CV board.
