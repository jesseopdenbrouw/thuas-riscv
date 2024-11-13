

#include <thuasrv32.h>

void wdt_start(void)
{
	WDT->CTRL |= WDT_EN;
}
