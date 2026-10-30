/*
 * Search the bus for 1-Wire devices
 *
 * From Application Note 187 "1-Wire Search Algorithm"
 *
 * https://www.analog.com/media/en/technical-documentation/app-notes/1wire-search-algorithm.pdf
 *
 * See library file 'onewire1_search.c'
 */

#include <thuasrv32.h>

#ifndef F_CPU
#define F_CPU (50000000UL)
#endif
#ifndef BAUD_RATE
#define BAUD_RATE (115200UL)
#endif

int main(void)
{
	int cnt = 0;
	uint8_t rom[8];
	int result;

	uart1_init(BAUD_RATE, UART_CTRL_EN);

	uart1_puts("1-Wire Bus Scan\r\n\n");

	while (1) {
		/* Find 'first' device, ROM code in 'rom' */
		result = onewire1_findfirst(rom);

		while (result) {
			uart1_puts("Device: ");
			for (int i = 0; i < 8; i++) {
				printhex(rom[i], 2);
			}
			uart1_puts("\r\n");
			cnt++;
			/* Find 'next' device, ROM code in 'rom' */
			result = onewire1_findnext(rom);
		}

		uart1_puts("Nr dev: ");
		printdec(cnt);
		uart1_puts("\r\n");
		delayms(1000);
		cnt = 0;
	}
}
