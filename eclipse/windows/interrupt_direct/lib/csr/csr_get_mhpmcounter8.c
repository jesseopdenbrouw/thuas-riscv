
/*
 * csr_get_mhpmcounter8.c -- Get mhpmcounter8
 *
 */

#include <stdint.h>

uint64_t csr_get_mhpmcounter8(void)
{
	register uint64_t themhpmcounter8;
	register uint32_t th,tl,tt;
	th = tl = tt = 0;

	 __asm__ volatile("1: csrr %0, mhpmcounter8h\n"
					  "   csrr %1, mhpmcounter8\n"
					  "   csrr %2, mhpmcounter8h\n"
					  "   bne %0, %2, 1b"
					  : "+r" (th), "+r" (tl), "+r" (tt));

	themhpmcounter8 = ((uint64_t)th << 32ULL) | (uint64_t) tl;
	return themhpmcounter8;
}
