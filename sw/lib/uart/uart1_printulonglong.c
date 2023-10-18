#include <stdint.h>

#include <thuasrv32.h>

/* Print decimal number with UART1 */
void uart1_printulonglong(uint64_t uv) {

	char buf[21] = { 0 };
	int i = 20;

	if (uv == 0) {
		uart1_putc('0');
		return;
	}

	while (uv > 0) {
		char c = (uv % 10) + '0';
		i--;
		buf[i] = c;
		uv /= 10;
	}
	uart1_puts(buf + i);
}
