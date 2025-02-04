/*
 * wdt_nmi.c - watchdog NMI test program
 */

#include <thuasrv32.h>

#ifndef F_CPU
#define F_CPU (50000000UL)
#endif
#ifndef BAUD_RATE
#define BAUD_RATE (115200UL)
#endif

__attribute__ ((interrupt))
void trap_handler(void);

int main(void)
{
	uart1_init(BAUD_RATE, UART_CTRL_EN);

	uart1_puts("\r\n\nWatchdog (WDT) test program\r\n\n");
	uart1_puts("Wait for it... (watch the processor take an NMI)");

	set_mtvec(trap_handler, TRAP_DIRECT_MODE);

	wdt_init(WDT_PRESCALER(0xfffff) | WDT_NMI | WDT_EN);

	while (1) {
		nop();
		nop();
	};
}

void trap_handler(void)
{
	uart1_puts("\r\nIn NMI!");
	wdt_start();
}

