/*
 * uart.h -- definitions for the UARTs
 */

#ifndef _UART_H
#define _UART_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Initialize UART1 */
void uart1_init(uint32_t baudrate, uint32_t ctrl);
/* Write one character to UART1 */
void uart1_putc(int ch);
/* Write null-terminated string to UART1 */
void uart1_puts(char *s);
/* Get one character from UART1 */
int uart1_getc(void);
/* Check if character has been received */
int uart1_hasreceived(void);
/* Get maximum size-1 characters in string buffer from UART1 */
int uart1_gets(char buffer[], int size);
/* Print formatted to UART1 */
int uart1_printf(const char *format, ...);
/* Print a signed long long int */
void uart1_printlonglong(int64_t v);
/* Print a unsigned long long integer */
void uart1_printulonglong(uint64_t uv);

#define UART_CTRL_PARITY_NONE (0 << 7)
#define UART_CTRL_PARITY_EVEN (2 << 7)
#define UART_CTRL_PARITY_ODD (3 << 7)
#define UART_CTRL_STOP1 (0 << 6)
#define UART_CTRL_STOP2 (1 << 6)
#define UART_CTRL_BRIE (1 << 5)
#define UART_CTRL_TCIE (1 << 4)
#define UART_CTRL_RCIE (1 << 3)
#define UART_CTRL_SIZE7 (3 << 1)
#define UART_CTRL_SIZE8 (0 << 1)
#define UART_CTRL_SIZE9 (2 << 1)
#define UART_CTRL_EN (1 << 0)

#define UART_STAT_FE (1 << 0)
#define UART_STAT_RF (1 << 1)
#define UART_STAT_PE (1 << 2)
#define UART_STAT_RC (1 << 3)
#define UART_STAT_TC (1 << 4)
#define UART_STAT_BR (1 << 5)

#define UART_CTRL_NONE (0)

#ifdef __cplusplus
}
#endif

#endif
