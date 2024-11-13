/*
 * gpio.h -- definitions for the GPIO
 */

#ifndef _GPIO_H
#define _GPIO_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

uint32_t gpioa_readpin(uint32_t pins);
void gpioa_writepin(uint32_t pins, uint32_t value);
void gpioa_togglepin(uint32_t pins);

#define GPIO_PIN_SET (1UL)
#define GPIO_PIN_RESET (0UL)

#define GPIO_PIN_0  (1UL <<  0UL)
#define GPIO_PIN_1  (1UL <<  1UL)
#define GPIO_PIN_2  (1UL <<  2UL)
#define GPIO_PIN_3  (1UL <<  3UL)
#define GPIO_PIN_4  (1UL <<  4UL)
#define GPIO_PIN_5  (1UL <<  5UL)
#define GPIO_PIN_6  (1UL <<  6UL)
#define GPIO_PIN_7  (1UL <<  7UL)
#define GPIO_PIN_8  (1UL <<  8UL)
#define GPIO_PIN_9  (1UL <<  9UL)
#define GPIO_PIN_10 (1UL << 10UL)
#define GPIO_PIN_11 (1UL << 11UL)
#define GPIO_PIN_12 (1UL << 12UL)
#define GPIO_PIN_13 (1UL << 13UL)
#define GPIO_PIN_14 (1UL << 14UL)
#define GPIO_PIN_15 (1UL << 15UL)
#define GPIO_PIN_16 (1UL << 16UL)
#define GPIO_PIN_17 (1UL << 17UL)
#define GPIO_PIN_18 (1UL << 18UL)
#define GPIO_PIN_19 (1UL << 19UL)
#define GPIO_PIN_20 (1UL << 20UL)
#define GPIO_PIN_21 (1UL << 21UL)
#define GPIO_PIN_22 (1UL << 22UL)
#define GPIO_PIN_23 (1UL << 23UL)
#define GPIO_PIN_24 (1UL << 24UL)
#define GPIO_PIN_25 (1UL << 25UL)
#define GPIO_PIN_26 (1UL << 26UL)
#define GPIO_PIN_27 (1UL << 27UL)
#define GPIO_PIN_28 (1UL << 28UL)
#define GPIO_PIN_29 (1UL << 29UL)
#define GPIO_PIN_30 (1UL << 30UL)
#define GPIO_PIN_31 (1UL << 31UL)

#define GPIO_PIN_ALL (0xffffffffUL)

#ifdef __cplusplus
}
#endif

#endif
