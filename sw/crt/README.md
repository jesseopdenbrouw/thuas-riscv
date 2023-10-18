# C runtime files

The C runtime files (CRT)

## Description

C runtime startup files

- `empty.S` (an empty startup file, only provides the `_startup` symbol)
- `minimal.S` (minimal, sets up the global pointer and stack pointer)
- `simple.S` (as minimal.S but calls `main` and halts after return from `main`)
- `startup.c` (full support for C programs, initializes globals, BSS etc)

## Status

Works
