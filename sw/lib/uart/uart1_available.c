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

/**
 * @file uart1_available.c
 * @brief Checks if a character is available on UART1
 *
 * @param[in] -
 * @param[out] int == 0 if not available, != 0 if available
 */
int uart1_available(void)
{
	return (UART1->STAT & 0x04);
}
