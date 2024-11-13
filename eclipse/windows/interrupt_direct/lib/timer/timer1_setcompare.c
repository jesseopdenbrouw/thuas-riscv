#include <stdint.h>

#include <thuasrv32.h>

void inline timer1_setcompare(uint32_t cmpt)
{
	TIMER1->CMPT = cmpt;
}
