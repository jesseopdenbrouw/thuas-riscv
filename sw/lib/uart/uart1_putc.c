#include <stdio.h>
#include <string.h>
#include <ctype.h>

/* THUASRV32 */
#include <thuasrv32.h>

/* Frequency of the DE0-CV board */
#ifndef F_CPU
#define F_CPU (50000000UL)
#endif
/* Transmission speed */
#ifndef BAUD_RATE
#define BAUD_RATE (9600UL)
#endif

/* Send one character over the UART1 */
void uart1_putc(int ch)
{
	/* Transmit data */
	UART1->DATA = (uint8_t) ch;

	/* Wait for transmission end */
	while ((UART1->STAT & 0x10) == 0);
}
