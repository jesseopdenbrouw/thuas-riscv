/*
 * watchdog.c - watchdog test program
 */

#include <thuasrv32.h>

#ifndef F_CPU
#define F_CPU (50000000UL)
#endif
#ifndef BAUD_RATE
#define BAUD_RATE (9600UL)
#endif

//#define DO_WDT_NORESET

int main(void)
{
	uart1_init(BAUD_RATE, UART_CTRL_EN);

	uart1_puts("\r\n\nWatchdog (WDT) test program\r\n\n");
#ifdef DO_WDT_NORESET
	uart1_puts("Processor should not reset\r\n");
#else
	uart1_puts("Wait for it... (watch the processor reset)");
#endif


	wdt_init(WDT_PRESCALER(0xfffff) | WDT_EN);

	while (1) {
#ifdef DO_WDT_NORESET
		delayms(100);
		wdt_reset();
#endif
	};
}
