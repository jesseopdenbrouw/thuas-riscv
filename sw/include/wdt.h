/*
 * wdt.h - header file watchdog definitions
 *
 */

#ifndef _WDT_H
#define _WDT_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

void wdt_init(uint32_t val);
void wdt_start(void);
void wdt_stop(void);
void wdt_reset(void);

#define WDT_EN (1 << 0)
#define WDT_NMI (1 << 1)
#define WDT_LOCK (1 << 7)
#define WDT_PRESCALER(A) ((A & 0x00ffffff) << 8)

#define WDT_PASSWORD (0x5c93a0f1)

#ifdef __cplusplus
}
#endif

#endif


