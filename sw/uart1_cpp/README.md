# uart1_cpp

A simple USART program written in C++

## Description

The USART code is build upon a singleton design pattern.
We included the option `-fno-threadsafe-statics`, which
disables thread safety, but reduces the compiled code
drastically.

Makefile is adapted for use with the g++ compiler.

## Status
Works on the board.
