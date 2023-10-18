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

void timer1_enable(void);
void timer1_disable(void);
void timer1_setcounter(uint32_t cntr);
uint32_t timer1_getcounter(void);
void timer1_setcompare(uint32_t cmpt);
void timer1_enable_interrupt(void);
void timer1_disable_interrupt(void);
void timer1_clear_interrupt(void);

#define TIMER1_EN (1 << 0)
#define TIMER1_TIE (1 << 4)
#define TIMER1_TCI (1 << 4)

#ifdef __cplusplus
}
#endif

#endif


