#include <stdio.h>
#include <stdint.h>

#include <thuasrv32.h>

#ifndef F_CPU
#define F_CPU (50000000UL)
#endif
#ifndef BAUD_RATE
#define BAUD_RATE (9600UL)
#endif

void print_cycle(void)
{
	uint64_t cycle = csr_get_cycle();

	uart1_printulonglong(cycle);
	
}

void print_instret(void)
{
	uint64_t instret = csr_get_instret();

	uart1_printulonglong(instret);
	
}

void print_time(void)
{
	uint64_t time = csr_get_time();

	uart1_printulonglong(time);
	
}

int main(int argc, char *argv[])
{
	uint32_t start;

	uart1_init(BAUD_RATE, UART_CTRL_NONE);
	uart1_puts("\r\n");
	uart1_puts(argv[0]);
	uart1_puts("\r\n");

	while (1) {
		uart1_puts("Time: ");
		print_time();
		uart1_puts("\r\n");

		/* Inhibit all counters */
		csr_write(mcountinhibit, -1);

		/* Show the result */
		uart1_puts("Counters should be stopped.\r\n");
		for (int i = 0; i < 1000; i++) {
			uart1_puts("instret: ");
			print_instret();
			uart1_puts(" | cycle: ");
			print_cycle();
			uart1_putc('\r');
		}
		uart1_puts("\r\n");

		/* Start all counters */
		csr_write(mcountinhibit, 0);

		uart1_puts("Counters should be running.\r\n");
		/* Show the result */
		for (int i = 0; i < 1000; i++) {
			uart1_puts("instret: ");
			print_instret();
			uart1_puts(" | cycle: ");
			print_cycle();
			uart1_putc('\r');
		}
		uart1_puts("\r\n");
	}

	return 0;
}
