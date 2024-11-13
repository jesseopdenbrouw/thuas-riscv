

#include <thuasrv32.h>

void wdt_stop(void)
{
	WDT->CTRL &= ~WDT_EN;
}
