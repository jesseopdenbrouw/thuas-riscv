#include "newlib.h"

#=========================================================================
# empty.S : Entry point for RISCV programs WITH NO STARTUP
#=========================================================================

# This is the startup section and must be the first to be called
  .section .text.start_up_code
  .global _start
  .type   _start, @function
_start:
  # Initialize global pointer
.option push
.option norelax

.option pop

  .size  _start, .-_start
