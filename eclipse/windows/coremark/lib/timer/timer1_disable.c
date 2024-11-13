#include <stdint.h>

#include <thuasrv32.h>

void inline timer1_disable(void)
{
	TIMER1->CTRL &= (~TIMER1_EN);
}
