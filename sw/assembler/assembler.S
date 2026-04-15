
	# This is the startup section and must be the first to be called
	  .section .text.start_up_code
	#  .text
	  .global _start
	  .global trap_handler
	  .type   _start, @function
	  .type   trap_handler, @function
	_start:
	  # Initialize global pointer
	.option push
	.option norelax

		la gp, __global_pointer$
		la sp, __stack_pointer$ 


		la t0, trap_handler
		csrw mtvec, t0
		li t0, 1 << 3
		csrw mie, t0


#		mop.rr.0 a0, a1, a2
#		mop.r.0 a0, a1


#		li t0,0x00ff0000
#		li t1,0xffffffff
		nop
		nop
#		clz a0, t0
#		clz a0, t1
		nop
		nop
#		ctz a0, t0
#		ctz a0, t1
		nop

		li t0,0x01234567
		li t1,0x89abcdef
#		pack a0, t1, t0
#		packh a1, t1, t0
#		brev8 a2, t0
#		zip a3, t0
#		unzip a4, a3

	einde:
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		j einde

		.word 0xffffffff
		.word 0xeeeeeeee
		.word 0xdddddddd

	.option pop

	  .size  _start, .-_start

trap_handler:
		nop
		nop
		j trap_handler
