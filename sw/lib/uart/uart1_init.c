/**
 * \file uartt_init.c
 * \brief initialize UART1
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
 * \fn uart1_init
 * \brief initialize UART1
 *
 * \param[in] uint32_t baudrate
 * \param[in] uint32_t ctrl
 * \param[out] -
 */
void uart1_init(uint32_t baudrate, uint32_t ctrl)
{
	/* Set baud rate generator */
	uint32_t speed = csr_read(0xfc1);
	speed = (speed == 0) ? F_CPU : speed;
	UART1->BAUD = (baudrate == 0) ? 0 : speed/baudrate-1;
	/* Set control register */
	UART1->CTRL = ctrl;
	/* Reset status register */
	UART1->STAT = 0x00;
}
