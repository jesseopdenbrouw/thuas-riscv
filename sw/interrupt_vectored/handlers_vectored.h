/*
 * handlers_vectored.h -- prototypes for handlers
 *
 * (c) 2024  Jesse E.J. op den Brouw
 *
 */

#ifndef _HANDLERS_VECTORED_H
#define _HANDLERS_VECTORED_H

#include <thuasrv32.h>

/* Debugger */
void debugger(trap_frame_t *tf);
/* TIMER1 compare match T interrupt */
void timer1_handler(void);
/* External timer handler */
void external_timer_handler(void);
/* USART receive and/or transmit interrupt */
void uart1_handler(void);
/* TIMER2 compare match T/A/B/C interrupts */
void timer2_handler(void);
/* SPI1 transmission complete interrupt */
void spi1_handler(void);
/* I2C1 transmit complete interrupt handler */
void i2c1_handler(void);
/* I2C2 transmit complete interrupt handler */
void i2c2_handler(void);
/* External software interrupt handler */
void external_msi_handler(void);
/* External input interrupt */
void external_input_handler(void);
/* Default (test) interrupt */
void default_handler(void);



#endif
