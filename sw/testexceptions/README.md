
# testexceptions

Test the implemented exceptions

## Description

This program tests the implemented exceptions in the design.
Implemented description:

* ECALL
* EBREAK
* Load access fault
* Store access fault
* Load misaligned fault
* Store misaligned fault
* Illegal instruction
* Instruction access fault
* Instruction misaligned fault

Most exceptions can easily created using simple assembler instructions.
Instruction access fault and instruction misaligned fault are created using carefully crafted returns, loading the `mepc` CSR with the address following the offending instruction. All other exceptions set the `mepc` CSR to the next instruction address.

## Status

Works on the board.
