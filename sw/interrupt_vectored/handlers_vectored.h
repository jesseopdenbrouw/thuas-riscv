/*
 * handlers.h -- prototypes for handlers
 *
 * (c) 2022  Jesse E.J. op den Brouw
 *
 */

#ifndef _HANDLERS_H
#define _HANDLERS_H

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
/* I2C1 transmit complete interrupt */
void i2c1_handler(void);
/* External input handler */
void external_input_handler(void);
/* Default handler */
void default_handler(void);
#endif
