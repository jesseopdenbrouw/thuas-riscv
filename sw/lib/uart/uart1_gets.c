#include <stdio.h>
#include <string.h>
#include <ctype.h>

/* THUASRV32 */
#include <thuasrv32.h>

/* Frequency of the DE0-CV board */
#ifndef F_CPU
#define F_CPU (50000000UL)
#endif
/* Transmission speed */
#ifndef BAUD_RATE
#define BAUD_RATE (9600UL)
#endif

/* Gets a string terminated by a newline character from UART1
 * The newline character is not part of the returned string.
 * The string is null-terminated.
 * A maximum of size-1 characters are read.
 * Some simple line handling is implemented */
int uart1_gets(char buffer[], int size)
{
	int index = 0;
	char chr;

	while (1) {
		chr = uart1_getc();
		switch (chr) {
			case '\n':
			case '\r':	buffer[index] = '\0';
					uart1_puts("\r\n");
					return index;
					break;
			/* Backspace key */
			case 0x7f:
			case '\b':	if (index>0) {
						uart1_putc(0x7f);
						index--;
					} else {
						uart1_putc('\a');
					}
					break;
			/* control-U */
			case 21:	while (index>0) {
						uart1_putc(0x7f);
						index--;
					}
					break;
			/* control-C */
			case 0x03:  	uart1_puts("<break>\r\n");
					index=0;
					break;
			default:	if (index<size-1) {
						if (chr>0x1f && chr<0x7f) {
							buffer[index] = chr;
							index++;
							uart1_putc(chr);
						}
					} else {
						uart1_putc('\a');
					}
					break;
		}
	}
	return index;
}

