/*
 * ansi_getscreensize.c - get the width and height of the terminal screen
 */

#include <thuasrv32.h>

ansi_screensize_t ansi_get_screensize(void)
{
	char buf[16] = { 0 };
	int i;
	char *pc;
	ansi_screensize_t pos = { 0, 0 };

	/* Save cursor pos, set term size really big, ask cursor pos, restore cursor pos */
	uart1_puts("\0337\033[r\033[999;999H\033[6n\0338");

	for (i = 0; i < sizeof buf / sizeof buf[0]; i++) {
		buf[i] = uart1_getc();
		if (buf[i] == 'R') {
			break;
		}
	}

	/* Check for ESC + '[' */
	if (buf[0] == '\x1b' && buf[1] == '[') {
		pos.height = parsedec(buf+2, &pc);
		pos.width = parsedec(pc+1, NULL);
	}

	return pos;
}
