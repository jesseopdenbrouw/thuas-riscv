#include <stdint.h>

#include <thuasrv32.h>

void inline timer1_disable_interrupt(void)
{
	TIMER1->CTRL &= (~TIMER1_TIE);
}
