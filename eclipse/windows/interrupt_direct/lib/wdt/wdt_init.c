

#include <thuasrv32.h>

void wdt_init(uint32_t val)
{
	WDT->CTRL = val;
}
