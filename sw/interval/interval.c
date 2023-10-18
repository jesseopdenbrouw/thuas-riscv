#include <stdio.h>
#include <time.h>
#include <sys/time.h>
#include <stdint.h>
#include <inttypes.h>

#include <thuasrv32.h>

/* Frequency of the DE0-CV board */
#ifndef F_CPU
#define F_CPU (50000000UL)
#endif
/* Transmission speed */
#ifndef BAUD_RATE
#define BAUD_RATE (9600UL)
#endif

int main(void)
{

	char buffer[100] = {0};

	uart1_init(BAUD_RATE, UART_CTRL_NONE);

	uart1_puts("\r\n\r\nInterval testing\r\n");

	snprintf(buffer, sizeof buffer, "Clocks per second: %d\r\n", CLOCKS_PER_SEC);
	uart1_puts(buffer);

	if (CLOCKS_PER_SEC != 1000000) {
		uart1_puts("Clocks per second should be 1000000!\r\n");
	}

	while (1) {

		clock_t current = clock();

		snprintf(buffer, sizeof buffer, "%lu\r\n", current);
		uart1_puts(buffer);

		uart1_puts("Wait....\r");

		while (clock() - current < 5*CLOCKS_PER_SEC);

		uart1_puts("5 seconds elapsed\r\n");
	}
	return 0;
}
