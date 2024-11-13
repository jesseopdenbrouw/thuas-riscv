/*
 * uart1_getc.c -- gets a character from UART1 (blocking mode)
 *
 */

/**
 * \file uart1_getc.c
 * \brief gets a character from UART1 (blocking mode)
 *
 */

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

/**
 * \fn uart1_getc.c
 * \brief gets a character from UART1 (blocking mode)
 *
 *
 * \param[in] -
 */
int uart1_getc(void)
{
	/* Wait for received character */
	while ((UART1->STAT & UART_STAT_RC) == 0);

	/* Return 8-bit data */
	return UART1->DATA & 0x000000ff;
}
