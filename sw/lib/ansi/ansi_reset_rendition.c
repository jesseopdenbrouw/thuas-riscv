/*
 * ansi_reset_screen.c - resets the screen to default
 */

#include <thuasrv32.h>

void ansi_reset_rendition(void)
{
	uart1_puts("\x1b[0m");
}
