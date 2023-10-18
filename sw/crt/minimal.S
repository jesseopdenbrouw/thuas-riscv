#include "newlib.h"

#=========================================================================
# minimal.S : Entry point for RISC-V programs WITH MINIMAL STARTUP
#=========================================================================

# This is the startup section and must be the first to be called
  .section .text.start_up_code
  .global _start
  .type   _start, @function
_start:
  # Initialize global pointer
.option push
.option norelax

	la   gp, __global_pointer$
	la   sp, __stack_pointer$
	call main
_halt:  j    _halt

.option pop

  .size  _start, .-_start
