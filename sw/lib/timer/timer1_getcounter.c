#include <stdint.h>

#include <thuasrv32.h>

uint32_t inline timer1_getcounter(void)
{
	return TIMER1->CNTR;
}
