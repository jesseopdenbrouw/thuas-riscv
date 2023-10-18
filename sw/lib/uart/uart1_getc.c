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

/* Get one character from the UART1 in
 * blocking mode */
int uart1_getc(void)
{
	/* Wait for received character */
	while ((UART1->STAT & 0x04) == 0);

	/* Return 8-bit data */
	return UART1->DATA & 0x000000ff;
}
