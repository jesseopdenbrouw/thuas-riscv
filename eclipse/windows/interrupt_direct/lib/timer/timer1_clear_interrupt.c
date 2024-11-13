#include <stdint.h>

#include <thuasrv32.h>

void inline timer1_clear_interrupt(void)
{
	TIMER1->STAT &= ~TIMER1_TCI;
}
