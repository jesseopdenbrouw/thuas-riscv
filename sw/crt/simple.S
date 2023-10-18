#include "newlib.h"

#=========================================================================
# crt0.S : Entry point for RISC-V user programs
#=========================================================================

# This is the startup section and must be the first to be called
  .section .text.start_up_code
#  .text
  .global _start
  .type   _start, @function

_start:
  # Initialize global pointer
.option push
.option norelax
  # Initialize global pointer
  la gp, __global_pointer$
  # Initialize stack pointer
  la sp, __stack_pointer$
  add s0, sp, zero

#  j _Initialize_System$

.option pop

  .size  _start, .-_start
