# uart1_cpp

A simple UART program written in C++

## Description

The UART code is build upon a singleton design pattern.
We included the option `-fno-threadsafe-statics`, which
disables thread safety, but reduces the compiled code
drastically.

Makefile is adapted for use with the g++ compiler.

## Status
Works on the board.
