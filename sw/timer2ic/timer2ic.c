#include <stdint.h>

#include <thuasrv32.h>

/* Should be loaded by the Makefile */
#ifndef F_CPU
#define F_CPU (50000000UL)
#endif
#ifndef BAUD_RATE
#define BAUD_RATE (9600UL)
#endif

int main(void)
{
	uart1_init(BAUD_RATE, UART_CTRL_NONE);
	uart1_puts("TIMER2 Input Capture\r\n");

	/* Set TIMER2 for maximum measument */
	TIMER2->CMPT = 0xffffUL;
	/* Prescaler 20 */
	TIMER2->PRSC = 19UL;
	/* Timer2 ICA */
	TIMER2->CMPA = 0UL;
	/* CMPT/B/C OFF 
	 * CMPA input compare
	 * 31: FOCC is off (force OC)
	 * 30: FOCB is off
	 * 29: FOCA is off
	 * 28: FOCT is off
	 * 27: PHAC is 0 (start phase)
	 * 26-24: MODEC is off
	 * 23: PHAB is 0
	 * 22-20: MODEB is off
	 * 19: PHAA is 0
	 * 18-16: MODEA is IC
	 * 15: PHAT is 0
	 * 14-12: MODET is off
	 * 11: PREC is 0 (preload)
	 * 10: PREB is 0
	 *  9: PREA is 0
	 *  8: PRET is 0
	 *  7: CIE is 0 (interrupt enable)
	 *  6: BIE is 0
	 *  5: AIE is 0
	 *  4: TIE is 0
	 *  3: OS is 0 (one-shot)
	 *  2-1: reserved
	 *  0: EN is 1 (timer enable) */
	TIMER2->CTRL = 0x00060001UL;

	while (1) {
		/* Clear counter */
		TIMER2->CNTR = 0UL;
		/* Clear flag */
		TIMER2->STAT = 0x00;
		/* Wait for first Input Capture */
		while ((TIMER2->STAT & (1 << 5)) == 0x00) {}
		/* Get value */
		uint32_t first = TIMER2->CMPA;
		/* Clear flag */
		TIMER2->STAT = 0x00;
		/* Wait for second Input Capture */
		while ((TIMER2->STAT & (1 << 5)) == 0x00) {}
		/* Get value */
		uint32_t second = TIMER2->CMPA;
		uart1_puts("First: ");
		printdec(first);
		uart1_puts(", second: ");
		printdec(second);
		uart1_puts(", diff: ");
		printdec(second-first);
		uart1_puts("\r\n");
		delayms(1000);
	}

	return 0;
}
