
/*
 * delayms - delay for some time (in milliseconds)
 */

#include <stdint.h>


#include <thuasrv32.h>


/* Frequency of the DE0-CV board */
#ifndef F_CPU
#define F_CPU (50000000UL)
#endif
/* Transmission speed */
#ifndef BAUD_RATE
#define BAUD_RATE (9600UL)
#endif

void delayms(uint32_t delay)
{
	uint32_t speed = csr_read(0xfc1);
	speed = (speed == 0) ? F_CPU : speed;

	uint32_t prems = speed/4000UL+1UL;
	uint32_t ms = delay*prems;

	asm volatile ("   mv t0, %[ms];"
	              "1: addi t0,t0,-1;"
	              "   bne t0,zero,1b;"
	              :
	              : [ms] "r" (ms)
                  : "t0");
}
