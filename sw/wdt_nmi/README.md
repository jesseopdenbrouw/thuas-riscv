# watchdog

Program to test the watchdog timer using NMI

## Description

This program tests if the Non-Maskable Interrupt is called
once the watchdog counter is expired. The trap handler must
(re)start or stop the watchdog. The NMI is not reentrant, so
an ongoing NMI cannot be interrupted by another NMI request.

## Status

Works on the board
