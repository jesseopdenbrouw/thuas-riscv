#include <stdio.h>
#include <string.h>
#include <ctype.h>

/* THUASRV32 */
#include <thuasrv32.h>

/* __io_getchar gets a character from the UART1 */
int __io_getchar(void)
{
	return uart1_getc();
}
