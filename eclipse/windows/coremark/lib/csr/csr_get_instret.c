
/*
 * csr_get_instret.c -- Get the number of retired instruction since last resec
 */

#include <stdint.h>

uint64_t csr_get_instret(void)
{
	register uint64_t theinstr;
	register uint32_t th,tl,tt;
	th = tl = tt = 0;

	 __asm__ volatile("1: rdinstreth %0\n"
					  "   rdinstret  %1\n"
					  "   rdinstreth %2\n"
					  "   bne %0, %2, 1b"
					  : "+r" (th), "+r" (tl), "+r" (tt));

    theinstr = ((uint64_t)th << 32ULL) | (uint64_t) tl;
	return theinstr;
}
