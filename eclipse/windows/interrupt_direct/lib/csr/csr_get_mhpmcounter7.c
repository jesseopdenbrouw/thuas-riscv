
/*
 * csr_get_mhpmcounter7.c -- Get mhpmcounter7
 *
 */

#include <stdint.h>

uint64_t csr_get_mhpmcounter7(void)
{
	register uint64_t themhpmcounter7;
	register uint32_t th,tl,tt;
	th = tl = tt = 0;

	 __asm__ volatile("1: csrr %0, mhpmcounter7h\n"
					  "   csrr %1, mhpmcounter7\n"
					  "   csrr %2, mhpmcounter7h\n"
					  "   bne %0, %2, 1b"
					  : "+r" (th), "+r" (tl), "+r" (tt));

	themhpmcounter7 = ((uint64_t)th << 32ULL) | (uint64_t) tl;
	return themhpmcounter7;
}
