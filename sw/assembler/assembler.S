
# This is the startup section and must be the first to be called
  .section .text.start_up_code
#  .text
  .global _start
  .global Universal_Handler
  .type   _start, @function
  .type   Universal_Hander, @function
_start:
  # Initialize global pointer
.option push
.option norelax

	la gp, __global_pointer$
	la sp, __stack_pointer$ 

	# Register trap hanlder and enable
	# interrupts (direct mode)

	//csrr t0, mie
	//ori  t0, t0, (1<<7)
	//csrw mie, t0

	csrr t0, mie
	ori  t0, t0, (1<<3)
	csrw mie, t0

	la t0, Universal_Handler
	csrw mtvec,t0
	li t0, 0x8 | (0x3<<11)
	csrw mstatus,t0


	nop
	nop
	nop

	la	t0, 0xf00000ec
	li  t1, 0x01
	sw  t1, 0(t0)

	nop
	nop
	nop



einde:	j einde

	nop
	nop
	nop
	nop
	nop
	nop

	nop
	nop
	nop


	nop
	nop


Universal_Handler:
	nop
	nop
	nop

	la	t0, 0xf00000ec
	li  t1, 0x00
	sw  t1, 0(t0)

	mret

hold:
	j hold

	# Load mcause to check for interrupt
	csrr x10,mcause
	blt  x10,x0,over

	# Add 4 to MEPC to skip the offending instruction
	csrr x10,mepc
	addi x10,x10,4
	csrw mepc,x9

over:
	nop

	sw x0,28(x7)
	nop

	mret
#	j Universal_Handler

.option pop

  .size  _start, .-_start
