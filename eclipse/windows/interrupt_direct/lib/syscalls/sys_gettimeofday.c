#include <stdio.h>
#include <time.h>
#include <sys/time.h>
#include <stdint.h>
#include <inttypes.h>

#include <stdint.h>

/* Get the system time in seconds and microseconds.
 * The time is read from the CSR TIME and TIMEH
 * because we have a 32-bit processor and the time
 * is measured in a 64-bit entity. We use inline
 * assembler to access the CSR registers. The timezone
 * is not used.  */

int _gettimeofday(struct timeval *tp, struct timezone *tz)
{
	uint64_t thetime;
	uint64_t usec;
	uint64_t sec;
	uint32_t th,tl,tt;
	th = tl = tt = 0;

	__asm__ volatile("1: rdtimeh %0\n"
                     "   rdtime  %1\n"
                     "   rdtimeh %2\n"
                     "   bne %0, %2, 1b"
                     : "+r" (th), "+r" (tl), "+r" (tt));

	thetime = ((uint64_t)th << 32ULL) | (uint64_t) tl;
	usec = thetime % 1000000ULL;
	sec = thetime / 1000000ULL;
	tp->tv_usec = (uint32_t) usec;
	tp->tv_sec = (uint64_t) sec;
	return 0;
}
