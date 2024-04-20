
/*
 * csr_get_mhpmcounter4.c -- Get mhpmcounter4
 *
 */

#include <stdint.h>

uint64_t csr_get_mhpmcounter4(void)
{
	register uint64_t themhpmcounter4;
	register uint32_t th,tl,tt;
	th = tl = tt = 0;

	 __asm__ volatile("1: csrr %0, mhpmcounter4h\n"
					  "   csrr %1, mhpmcounter4\n"
					  "   csrr %2, mhpmcounter4h\n"
					  "   bne %0, %2, 1b"
					  : "+r" (th), "+r" (tl), "+r" (tt));

	themhpmcounter4 = ((uint64_t)th << 32ULL) | (uint64_t) tl;
	return themhpmcounter4;
}
