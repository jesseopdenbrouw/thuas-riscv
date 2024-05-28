# wfitest

Test the `WFI` instruction

## Description

This program tests the use of the `WFI` instruction.
The `WFI` instruction halts the processor until an
interrupt needs to be serviced. The External Input
Interrupt (EXTI) is assigned for that task.

The EXTI waits for a falling edge in pin PA15 of
GPIOA. On the DE0-CV board, this is push button
`KEY3`, which is active low.


## Stats

Works on the DE0-CV board.
