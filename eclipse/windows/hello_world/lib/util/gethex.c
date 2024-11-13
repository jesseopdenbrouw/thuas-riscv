#include <ctype.h>
#include <stdint.h>

#include <thuasrv32.h>

/* Get a unsigned hex number from UART1, n is the number of
 * ASCII characters representing the hex number */
uint32_t gethex(int n) {

	uint32_t v = 0;
	
	for (int i = 0; i < n; i++) {
		int c = uart1_getc();
		v <<= 4;
		if (isdigit(c)) {
			v |= c - '0';
		} else if (isxdigit(c)) {
			v |= tolower(c) - 'a' + 10;
		}
	}
	return v;
}
