/*
 * ansi_set_background.c - set the background color (256 colors)
 */

#include <thuasrv32.h>

void ansi_set_background_(uint32_t color)
{
	uart1_puts("\x1b[48;5;");
	printdec(color);
	uart1_putc('m');
}

