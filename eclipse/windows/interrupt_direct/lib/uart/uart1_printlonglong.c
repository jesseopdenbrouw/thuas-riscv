#include <stdint.h>

#include <thuasrv32.h>

/* Print signed long long number with UART1 */
void uart1_printlonglong(int64_t v) {

	char buf[21] = { 0 };
	uint64_t uv;
	int i = 20;

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
