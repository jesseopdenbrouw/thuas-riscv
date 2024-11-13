#include <stdint.h>

#include <thuasrv32.h>

/* Print hex string with UART1, n is number of hex characters */
void printhex(uint32_t v, int n) {
	char buf[9] = { 0 };

	if (n < 1 || n > 8) {
		n = 8;
	}
	for (int i = 0; i < n; i++) {
		char c = (v & 0x0f) + '0';
		if (c > '9') {
			c += 'a' - '0' - 10;
		}
		buf[n-1-i] = c;
		v >>= 4;
	}
	uart1_puts(buf);
}
