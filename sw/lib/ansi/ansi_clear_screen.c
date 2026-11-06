/*
 * ansi_clear_screen.c - clear the terminal screen and goto the upper left corner
 */

#include <thuasrv32.h>

void ansi_clear_screen(void)
{
    uart1_puts("\x1b[2J\x1b[H");
}

