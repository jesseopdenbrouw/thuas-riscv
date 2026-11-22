/*
 * ansi_disable_cursor.c - disables displaying of the cursor
 */

#include <thuasrv32.h>

void ansi_disable_cursor(void)
{
    uart1_puts("\x1b[?25l");
}

