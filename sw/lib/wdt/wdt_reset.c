

#include <thuasrv32.h>

void wdt_reset(void)
{
	WDT->TRIG = WDT_PASSWORD;
}
