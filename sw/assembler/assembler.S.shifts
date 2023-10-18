
# This is the startup section and must be the first to be called
  .section .text.start_up_code
#  .text
  .global _start
  .type   _start, @function
_start:
  # Initialize global pointer
.option push
.option norelax

	li	x5,0xffffffff
	slli    x4,x5,31
	slli    x4,x5,30
	slli    x4,x5,29
	slli    x4,x5,28
	slli    x4,x5,27
	slli    x4,x5,26
	slli    x4,x5,25
	slli    x4,x5,24
	slli    x4,x5,23
	slli    x4,x5,22
	slli    x4,x5,21
	slli    x4,x5,20
	slli    x4,x5,19
	slli    x4,x5,18
	slli    x4,x5,17
	slli    x4,x5,16
	slli    x4,x5,15
	slli    x4,x5,14
	slli    x4,x5,13
	slli    x4,x5,12
	slli    x4,x5,11
	slli    x4,x5,10
	slli    x4,x5,9
	slli    x4,x5,8
	slli    x4,x5,7
	slli    x4,x5,6
	slli    x4,x5,5
	slli    x4,x5,4
	slli    x4,x5,3
	slli    x4,x5,2
	slli    x4,x5,1
	slli    x4,x5,0

	nop
	nop
	nop
	nop
	nop
	nop
	nop

	srli    x4,x5,31
	srli    x4,x5,30
	srli    x4,x5,29
	srli    x4,x5,28
	srli    x4,x5,27
	srli    x4,x5,26
	srli    x4,x5,25
	srli    x4,x5,24
	srli    x4,x5,23
	srli    x4,x5,22
	srli    x4,x5,21
	srli    x4,x5,20
	srli    x4,x5,19
	srli    x4,x5,18
	srli    x4,x5,17
	srli    x4,x5,16
	srli    x4,x5,15
	srli    x4,x5,14
	srli    x4,x5,13
	srli    x4,x5,12
	srli    x4,x5,11
	srli    x4,x5,10
	srli    x4,x5,9
	srli    x4,x5,8
	srli    x4,x5,7
	srli    x4,x5,6
	srli    x4,x5,5
	srli    x4,x5,4
	srli    x4,x5,3
	srli    x4,x5,2
	srli    x4,x5,1
	srli    x4,x5,0

	nop
	nop
	nop
	nop
	nop
	nop
	nop

	li	x5,0x80000000
	srai    x4,x5,31
	srai    x4,x5,30
	srai    x4,x5,29
	srai    x4,x5,28
	srai    x4,x5,27
	srai    x4,x5,26
	srai    x4,x5,25
	srai    x4,x5,24
	srai    x4,x5,23
	srai    x4,x5,22
	srai    x4,x5,21
	srai    x4,x5,20
	srai    x4,x5,19
	srai    x4,x5,18
	srai    x4,x5,17
	srai    x4,x5,16
	srai    x4,x5,15
	srai    x4,x5,14
	srai    x4,x5,13
	srai    x4,x5,12
	srai    x4,x5,11
	srai    x4,x5,10
	srai    x4,x5,9
	srai    x4,x5,8
	srai    x4,x5,7
	srai    x4,x5,6
	srai    x4,x5,5
	srai    x4,x5,4
	srai    x4,x5,3
	srai    x4,x5,2
	srai    x4,x5,1
	srai    x4,x5,0

	nop
	nop
	nop
	nop
	nop
	nop
	nop

	li	x4,0x7fffffff
	li	x5,0x00000001
	add	x3,x4,x5
	sub	x3,x3,x5

	nop
	nop

	li	x4,0x7fffffff
	li	x5,0x80000000
	sub	x3,x4,x5

einde:	j einde

.option pop

  .size  _start, .-_start
