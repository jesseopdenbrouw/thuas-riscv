#include <stdint.h>

#include <thuasrv32.h>

void inline timer1_enable(void)
{
	TIMER1->CTRL |= TIMER1_EN;
}
