/*
 * ansi_enable_cursor.c - enables the displaying of the cursor
 */

#include <thuasrv32.h>

void ansi_enable_cursor(void)
{
    uart1_puts("\x1b[?25h");
}

