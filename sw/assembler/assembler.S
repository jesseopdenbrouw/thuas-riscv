
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

#	la t0, Universal_Handler
#	csrw mtvec,t0
#	li t0, 0x8 | (0x3<<11)
#	csrw mstatus,t0

#	czero.nez x5,x6,x7
#	czero.eqz x5,x6,x7

/*
	li x6,0
	li x5,0

	bseti x5,x6,23
	binvi x6,x5,22
	bseti x5,x6,3

	li x10,23
	li x11,22
	li x12,3

	li x6,0
	li x5,0

	bset x5,x6,x10
	binv x6,x5,x11
	bset x5,x6,x12
*/

	nop
	nop

/*

	li t0, 0x00000001
	la t1, 0x20000000

	nop
	nop

	sw t0, 0(t1)
	sw t0, 4(t1)
	sw t0, 8(t1)
	sw t0, 12(t1)
	sw t0, 16(t1)
	sw t0, 20(t1)
	lw t2, 20(t1)
	lw t3, 20(t1)
	lw t4, 20(t1)
	lw t5, 20(t1)
*/

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
