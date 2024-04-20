
/*
 * csr_get_mhpmcounter3.c -- Get mhpmcounter3
 *
 */

#include <stdint.h>

uint64_t csr_get_mhpmcounter3(void)
{
	register uint64_t themhpmcounter3;
	register uint32_t th,tl,tt;
	th = tl = tt = 0;

	 __asm__ volatile("1: csrr %0, mhpmcounter3h\n"
					  "   csrr %1, mhpmcounter3\n"
					  "   csrr %2, mhpmcounter3h\n"
					  "   bne %0, %2, 1b"
					  : "+r" (th), "+r" (tl), "+r" (tt));

	themhpmcounter3 = ((uint64_t)th << 32ULL) | (uint64_t) tl;
	return themhpmcounter3;
}
