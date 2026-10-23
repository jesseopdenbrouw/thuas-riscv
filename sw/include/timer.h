/*
 * timer.h - header file timer definitions
 *
 */

#ifndef _TIMER_H
#define _TIMER_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Enable TIMER1 */
void timer1_enable(void);
/* Disable TIMER1 */
void timer1_disable(void);
/* Set CNTR register */
void timer1_setcounter(uint32_t cntr);
/* Get CNTR register */
uint32_t timer1_getcounter(void);
/* Set CMPT register */
void timer1_setcompare(uint32_t cmpt);
/* Enable interrupt */
void timer1_enable_interrupt(void);
/* Disable interrupt */
void timer1_disable_interrupt(void);
/* Clear pending interrupt flag */
void timer1_clear_interrupt(void);

#define TIMER1_EN   (1 << 0)
#define TIMER1_TCIE (1 << 4)
#define TIMER1_TC   (1 << 4)

#ifdef __cplusplus
}
#endif

#endif


