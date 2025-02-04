/*
 * uart1_hasreceived.c -- check if a character is received
 *
 */

/**
 * @file uart1_hasreceived.c
 * @brief Checks if a character is available on UART1
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
#define BAUD_RATE (115200UL)
#endif

/**
 * @fn uart1_hasreceived.c
 * @brief Checks if a character is available on UART1
 *
 * @param[in] -
 * @param[out] int == 0 if not available, != 0 if available
 */
int uart1_hasreceived(void)
{
	return (UART1->STAT & UART_STAT_RC);
}
