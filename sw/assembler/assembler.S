
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

		la t0, Universal_Handler
		csrw mtvec,t0
		li t0, 0x8 | (0x3<<11)
		csrw mstatus,t0

		nop
		nop
		nop
		nop
/*
		li t0,0x12345678
		rev8	t0,t0

		li	t0, 0xffffffff
		clz	t1, t0
		srl t0, t0, 1
		clz	t1, t0
		srl t0, t0, 1
		clz	t1, t0
		srl t0, t0, 1
		clz	t1, t0
		srl t0, t0, 1
		clz	t1, t0
		srl t0, t0, 1
		clz	t1, t0
		srl t0, t0, 1
		clz	t1, t0
		srl t0, t0, 1
		clz	t1, t0
		srl t0, t0, 1
		clz	t1, t0
		srl t0, t0, 1
		clz	t1, t0
		srl t0, t0, 1
		clz	t1, t0
		srl t0, t0, 1
		clz	t1, t0
		srl t0, t0, 1
		clz	t1, t0
		srl t0, t0, 1
		clz	t1, t0
		srl t0, t0, 1
		clz	t1, t0
		srl t0, t0, 1
		clz	t1, t0
		srl t0, t0, 1
		clz	t1, t0
		srl t0, t0, 1
		clz	t1, t0
		srl t0, t0, 1
		clz	t1, t0
		srl t0, t0, 1
		clz	t1, t0
		srl t0, t0, 1
		clz	t1, t0
		srl t0, t0, 1
		clz	t1, t0
		srl t0, t0, 1
		clz	t1, t0
		srl t0, t0, 1
		clz	t1, t0
		srl t0, t0, 1
		clz	t1, t0
		srl t0, t0, 1
		clz	t1, t0
		srl t0, t0, 1
		clz	t1, t0
		srl t0, t0, 1
		clz	t1, t0
		srl t0, t0, 1
		clz	t1, t0
		srl t0, t0, 1
		clz	t1, t0
		srl t0, t0, 1
		clz	t1, t0
		srl t0, t0, 1
		clz	t1, t0
		srl t0, t0, 1
		clz	t1, t0
		srl t0, t0, 1
		clz	t1, t0

		li	t0, 0xffffffff
		ctz	t1, t0
		sll t0, t0, 1
		ctz	t1, t0
		sll t0, t0, 1
		ctz	t1, t0
		sll t0, t0, 1
		ctz	t1, t0
		sll t0, t0, 1
		ctz	t1, t0
		sll t0, t0, 1
		ctz	t1, t0
		sll t0, t0, 1
		ctz	t1, t0
		sll t0, t0, 1
		ctz	t1, t0
		sll t0, t0, 1
		ctz	t1, t0
		sll t0, t0, 1
		ctz	t1, t0
		sll t0, t0, 1
		ctz	t1, t0
		sll t0, t0, 1
		ctz	t1, t0
		sll t0, t0, 1
		ctz	t1, t0
		sll t0, t0, 1
		ctz	t1, t0
		sll t0, t0, 1
		ctz	t1, t0
		sll t0, t0, 1
		ctz	t1, t0
		sll t0, t0, 1
		ctz	t1, t0
		sll t0, t0, 1
		ctz	t1, t0
		sll t0, t0, 1
		ctz	t1, t0
		sll t0, t0, 1
		ctz	t1, t0
		sll t0, t0, 1
		ctz	t1, t0
		sll t0, t0, 1
		ctz	t1, t0
		sll t0, t0, 1
		ctz	t1, t0
		sll t0, t0, 1
		ctz	t1, t0
		sll t0, t0, 1
		ctz	t1, t0
		sll t0, t0, 1
		ctz	t1, t0
		sll t0, t0, 1
		ctz	t1, t0
		sll t0, t0, 1
		ctz	t1, t0
		sll t0, t0, 1
		ctz	t1, t0
		sll t0, t0, 1
		ctz	t1, t0
		sll t0, t0, 1
		ctz	t1, t0
		sll t0, t0, 1
		ctz	t1, t0
		sll t0, t0, 1
		ctz	t1, t0
		sll t0, t0, 1

		li	t0, 0xffffffff
		cpop	t1, t0
		sll t0, t0, 1
		cpop	t1, t0
		sll t0, t0, 1
		cpop	t1, t0
		sll t0, t0, 1
		cpop	t1, t0
		sll t0, t0, 1
		cpop	t1, t0
		sll t0, t0, 1
		cpop	t1, t0
		sll t0, t0, 1
		cpop	t1, t0
		sll t0, t0, 1
		cpop	t1, t0
		sll t0, t0, 1
		cpop	t1, t0
		sll t0, t0, 1
		cpop	t1, t0
		sll t0, t0, 1
		cpop	t1, t0
		sll t0, t0, 1
		cpop	t1, t0
		sll t0, t0, 1
		cpop	t1, t0
		sll t0, t0, 1
		cpop	t1, t0
		sll t0, t0, 1
		cpop	t1, t0
		sll t0, t0, 1
		cpop	t1, t0
		sll t0, t0, 1
		cpop	t1, t0
		sll t0, t0, 1
		cpop	t1, t0
		sll t0, t0, 1
		cpop	t1, t0
		sll t0, t0, 1
		cpop	t1, t0
		sll t0, t0, 1
		cpop	t1, t0
		sll t0, t0, 1
		cpop	t1, t0
		sll t0, t0, 1
		cpop	t1, t0
		sll t0, t0, 1
		cpop	t1, t0
		sll t0, t0, 1
		cpop	t1, t0
		sll t0, t0, 1
		cpop	t1, t0
		sll t0, t0, 1
		cpop	t1, t0
		sll t0, t0, 1
		cpop	t1, t0
		sll t0, t0, 1
		cpop	t1, t0
		sll t0, t0, 1
		cpop	t1, t0
		sll t0, t0, 1
		cpop	t1, t0
		sll t0, t0, 1
		cpop	t1, t0
		sll t0, t0, 1
		cpop	t1, t0

		li	t0, 0x11001100
		orc.b t1, t0

		li	t0, 0xffffffff
		li	t1, 0x00000001
		min	t2, t1, t0
		minu	t2, t1, t0
		max	t2, t1, t0
		maxu	t2, t1, t0

		li	t0, 0x0000f000
		sext.h	t0, t0

		li	t0, 0xff
		sext.b	t0, t0

		li t0, 0xf0000001
		li t1, 1
		rol t2, t0, t1
		addi t1, t1, 1
		rol t2, t0, t1
		li t1, 31
		rol t2, t0, t1


		li t0, 0xf0000001
		li t1, 1
		ror t2, t0, t1
		li t1, 2
		ror t2, t0, t1
		li t1, 3
		ror t2, t0, t1
		rori t2, t0, 4
		rori t2, t0, 5
		rori t2, t0, 6
		rori t2, t0, 7
		rori t2, t0, 8
		rori t2, t0, 9
		rori t2, t0, 10
		rori t2, t0, 11
		rori t2, t0, 12
		rori t2, t0, 13
		rori t2, t0, 14
		rori t2, t0, 15
		rori t2, t0, 16
		rori t2, t0, 17
		rori t2, t0, 18
		rori t2, t0, 19
		rori t2, t0, 20
*/

	einde:
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		j einde



	Universal_Handler:
		nop
		nop
		nop

		# Load mcause to check for interrupt
		csrr x10,mcause
		blt  x10,x0,over

		# Add 4 to MEPC to skip the offending instruction
		csrr x10,mepc
		addi x10,x10,4
		csrw mepc,x10

	over:
		mret

	.option pop

	  .size  _start, .-_start
