# watchdog

Program to test the watchdog timer.

## Description

This program tests the watchdog timer. The watchdog timer must be enabled in the IO.
By default, the program sets the watchdog counter to a specific value and lets
the watchdog generate an system wide reset.

By defining the macro `DO_WDT_NORESET`, the watchdog is triggered in time so it
doesn't trigger a reset.

## Status

Works on the board
