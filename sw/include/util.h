/*
 * util.h -- utility functions for the THUAS RISCV processor
 *
 */
#ifndef _UTIL_H_
#define _UTIL_H_

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Parse hex number from string */
uint32_t parsehex(char *s, char **ppchar);
/* Print hex number to UART1 */
void printhex(uint32_t v, int n);
/* Print signed decimal number to UART1 */
void printdec(int32_t v);
/* Get a hex number from UART1 */
uint32_t gethex(int n);
/* Delay in milliseconds */
void delayms(uint32_t delay);

#ifdef __cplusplus
}
#endif

#endif
