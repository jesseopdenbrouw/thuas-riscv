/*
 * ansi_set_color.c - sets the foreground color (extends to 256 colors)
 */

#include <thuasrv32.h>

void ansi_set_color(uint32_t color)
{
	uart1_puts("\x1b[38;5;");
	printdec(color);
	uart1_putc('m');
}
