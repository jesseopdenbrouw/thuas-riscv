
/*
 * csr_get_cycle.c -- Get the number of clock cycles the
 *                    processor is running since last reset
 */

#include <stdint.h>

uint64_t csr_get_cycle(void)
{
	register uint64_t thecycle;
	register uint32_t th,tl,tt;
	th = tl = tt = 0;

	 __asm__ volatile("1: rdcycleh %0\n"
					  "   rdcycle  %1\n"
					  "   rdcycleh %2\n"
					  "   bne %0, %2, 1b"
					  : "+r" (th), "+r" (tl), "+r" (tt));

    thecycle = ((uint64_t)th << 32ULL) | (uint64_t) tl;
	return thecycle;
}
