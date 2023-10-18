#include <thuasrv32.h>

/* Frequency of the DE0-CV board */
#ifndef F_CPU
#define F_CPU (50000000UL)
#endif
/* Transmission speed */
#ifndef BAUD_RATE
#define BAUD_RATE (9600UL)
#endif

int main(void)
{

	/* Set baud rate generator */
	uint32_t speed = csr_read(0xfc1);
	speed = (speed == 0) ? F_CPU : speed;
	UART1->BAUD = speed/BAUD_RATE-1;

	/* Set one stop bit, no parity */
	UART1->CTRL = 0x00;

	/* Read 8 switches from input */
	UART1->DATA = GPIOA->PIN & 0x000000ff;

	/* Wait for transmission end */
	while ((UART1->STAT & 0x10) == 0);

	/* Wait for received character */
	while ((UART1->STAT & 0x04) == 0);

	/* Put data on leds */
	GPIOA->POUT = UART1_DATA;

	return 0;
}
