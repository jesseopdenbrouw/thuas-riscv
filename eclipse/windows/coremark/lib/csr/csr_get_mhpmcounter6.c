
/*
 * csr_get_mhpmcounter6.c -- Get mhpmcounter6
 *
 */

#include <stdint.h>

uint64_t csr_get_mhpmcounter6(void)
{
	register uint64_t themhpmcounter6;
	register uint32_t th,tl,tt;
	th = tl = tt = 0;

	 __asm__ volatile("1: csrr %0, mhpmcounter6h\n"
					  "   csrr %1, mhpmcounter6\n"
					  "   csrr %2, mhpmcounter6h\n"
					  "   bne %0, %2, 1b"
					  : "+r" (th), "+r" (tl), "+r" (tt));

	themhpmcounter6 = ((uint64_t)th << 32ULL) | (uint64_t) tl;
	return themhpmcounter6;
}
