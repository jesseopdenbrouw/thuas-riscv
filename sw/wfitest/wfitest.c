/*
 * wfitest.c -- Test the WFI instruction
 *
 */

#include <thuasrv32.h>

#ifndef BAUD_RATE
#define BAUD_RATE (115200UL)
#endif

__attribute__ ((interrupt))
void trap_handler(void);

int main(void)
{
	uart1_init(BAUD_RATE, UART_CTRL_EN);

	uart1_puts("\r\nWFI test\r\nPress push button\r\n\n");

	set_mtvec(trap_handler, TRAP_DIRECT_MODE);

	enable_irq();

	GPIOA->EXTC = (15 << 3) | (2 << 1);

	while (1) {
		wfi();
		uart1_puts("You pressed the button!\r\n");
		gpioa_togglepin(GPIO_PIN_0);
	}
}

__attribute__ ((interrupt))
void trap_handler(void)
{
	GPIOA->EXTS = 0x00;
}
