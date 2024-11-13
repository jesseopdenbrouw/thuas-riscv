
/*
 * csr_get_mhpmcounter9.c -- Get mhpmcounter9
 *
 */

#include <stdint.h>

uint64_t csr_get_mhpmcounter9(void)
{
	register uint64_t themhpmcounter9;
	register uint32_t th,tl,tt;
	th = tl = tt = 0;

	 __asm__ volatile("1: csrr %0, mhpmcounter9h\n"
					  "   csrr %1, mhpmcounter9\n"
					  "   csrr %2, mhpmcounter9h\n"
					  "   bne %0, %2, 1b"
					  : "+r" (th), "+r" (tl), "+r" (tt));

	themhpmcounter9 = ((uint64_t)th << 32ULL) | (uint64_t) tl;
	return themhpmcounter9;
}
