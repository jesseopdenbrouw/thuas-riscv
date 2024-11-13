#include <stdint.h>

#include <thuasrv32.h>

/* Print decimal number with UART1 */
void printdec(int32_t v) {

	char buf[12] = { 0 };
	uint32_t uv;
	int i = 11;

	if (v == 0) {
		uart1_putc('0');
		return;
	} else if (v < 0) {
		uart1_putc('-');
		uv = -v;
	} else {
		uv = v;
	}

	while (uv > 0) {
		char c = (uv % 10) + '0';
		i--;
		buf[i] = c;
		uv /= 10;
	}
	uart1_puts(buf + i);
}
