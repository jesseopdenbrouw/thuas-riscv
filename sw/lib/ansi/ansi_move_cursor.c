/*
 * ansi_move_cursor.c - moves cursor to (x, y) -- positions start from (1, 1)
 */

#include <thuasrv32.h>

void ansi_move_cursor(int x, int y)
{
    uart1_puts("\x1b[");
    printdec(y);
    uart1_putc(';');
    printdec(x);
    uart1_putc('H');
}
