# ctor_cpp

Test global constructors in C++ programs.

## Description

This program tests if global constructors are called upon program execution.
To test global destructors (after `main`, before `exit`), goto to the `crt`
directory and define macro `WITH_DESTRUCTORS` in file `startup.c`.

## Status

Works on the board
