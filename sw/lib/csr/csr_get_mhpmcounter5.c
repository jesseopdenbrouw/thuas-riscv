
/*
 * csr_get_mhpmcounter5.c -- Get mhpmcounter5
 *
 */

#include <stdint.h>

uint64_t csr_get_mhpmcounter5(void)
{
	register uint64_t themhpmcounter5;
	register uint32_t th,tl,tt;
	th = tl = tt = 0;

	 __asm__ volatile("1: csrr %0, mhpmcounter5h\n"
					  "   csrr %1, mhpmcounter5\n"
					  "   csrr %2, mhpmcounter5h\n"
					  "   bne %0, %2, 1b"
					  : "+r" (th), "+r" (tl), "+r" (tt));

	themhpmcounter5 = ((uint64_t)th << 32ULL) | (uint64_t) tl;
	return themhpmcounter5;
}
