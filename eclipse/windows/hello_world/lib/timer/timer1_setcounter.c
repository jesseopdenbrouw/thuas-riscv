#include <stdint.h>

#include <thuasrv32.h>

void inline timer1_setcounter(uint32_t cntr)
{
	TIMER1->CNTR = cntr;
}
