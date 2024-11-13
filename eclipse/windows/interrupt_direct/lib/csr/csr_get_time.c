
/*
 * csr_get_time.c -- Get the time is microseconds since last reset
 */

#include <stdint.h>

uint64_t csr_get_time(void)
{
	register uint64_t thetime;
	register uint32_t th,tl,tt;
	th = tl = tt = 0;

	 __asm__ volatile("1: rdtimeh %0\n"
					  "   rdtime  %1\n"
					  "   rdtimeh %2\n"
					  "   bne %0, %2, 1b"
					  : "+r" (th), "+r" (tl), "+r" (tt));

    thetime = ((uint64_t)th << 32ULL) | (uint64_t) tl;
	return thetime;
}
