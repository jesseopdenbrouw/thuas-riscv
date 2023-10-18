
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

	la t0, Universal_Handler
	csrw mtvec,t0
	li t0, 0x8 | (0x3<<11)
	csrw mstatus,t0

	la	x4,0x00000000
	lw	x5,0(x4)

	la	x4,0x20000000
	sw	x5,0(x4)

	nop
	nop
	# ECALL
	ecall
	nop
	nop
	# EBREAK
	ebreak
	nop
	nop
	# Illegal instruction
	.word 0x00000000
	nop
	nop
	# Load access fault
	la	x5,0x10000000
	lw	x3,0(x5)
	nop
	nop
	# Store access fault
	sw	x3,0(x5)
	nop
	nop
	la	x5,0x000000
	lw	x3,0(x5)
	nop
	nop

	# Load misaligned error
	lw      x4,2(x5)

	nop
	nop

	div     x3,x4,x5
	nop
	nop

	lw      x3,0(x5)
	nop
	nop     


#	la	x5,0x3
#	jalr	x5


einde:	j einde

	.word 0xffffffff
	.word 0xffffffff

Universal_Handler:
	nop
	nop
	nop
	mret
#	j Universal_Handler

.option pop

  .size  _start, .-_start
