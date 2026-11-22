#include <errno.h>
#include <stdio.h>
#include <signal.h>
#include <time.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <sys/times.h>
#include <stdint.h>
#include <inttypes.h>

/* System call for _times. Loads the system time
 * since last reset in microseconds. This version
 * reads the TIME and TIMEH registers from the CSR.
 */

int _times(struct tms *buf)
{
	uint64_t thetime;
	uint32_t th,tl,tt;
	th = tl = tt = 0;

	__asm__ volatile("1: rdtimeh %0\n"
                     "   rdtime  %1\n"
                     "   rdtimeh %2\n"
                     "   bne %0, %2, 1b"
                     : "+r" (th), "+r" (tl), "+r" (tt));

	thetime = ((uint64_t)th << 32ULL) | (uint64_t) tl;
	buf->tms_utime = (uint64_t) thetime;
	buf->tms_stime = 0;
	buf->tms_cutime = 0;
	buf->tms_cstime = 0;

	return 0;
}
