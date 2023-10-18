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
#define BAUD_RATE (9600ULL)
#endif

int main(void)
{
	int64_t sec, min, hour;
	struct timeval t;

	char buffer[100] = {0};

	uart1_init(BAUD_RATE, UART_CTRL_NONE);

	uart1_puts("\r\n\r\nTime since last reset:\r\n");

	while (1) {
		gettimeofday(&t, NULL);

		sec = t.tv_sec % 60LL;

		min = (t.tv_sec / 60LL) % 60LL;

		hour = (t.tv_sec / 3600LL);

		snprintf(buffer, sizeof buffer, "%ld.%06ld | %03ld:%02ld:%02ld           \r", (int32_t) t.tv_sec, (int32_t)t.tv_usec, (int32_t)hour, (int32_t)min, (int32_t)sec);
		uart1_puts(buffer);
	}
	return 0;
}
