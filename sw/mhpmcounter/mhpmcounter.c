#include <stdio.h>
#include <stdint.h>

#include <thuasrv32.h>

#ifndef F_CPU
#define F_CPU (50000000UL)
#endif
#ifndef BAUD_RATE
#define BAUD_RATE (9600UL)
#endif

void trap_handler(void);

int main(int argc, char *argv[])
{
	uint32_t count = 0;

	uart1_init(BAUD_RATE, UART_CTRL_EN);

	set_mtvec(trap_handler, TRAP_DIRECT_MODE);

	csr_write(mhpmevent3, 1);
	csr_write(mhpmevent4, 2);
	csr_write(mhpmevent5, 4);
	csr_write(mhpmevent6, 8);
	csr_write(mhpmevent7, 16);
	csr_write(mhpmevent8, 32);
	csr_write(mhpmevent9, 64);

	uart1_puts("c3 counts branch/jump\r\n");
	uart1_puts("c4 counts stall cycles\r\n");
	uart1_puts("c5 counts stores\r\n");
	uart1_puts("c6 counts loads\r\n");
	uart1_puts("c7 counts ECALLs\r\n");

	while (1) {

		uart1_puts("c3: ");
		uart1_printulonglong(csr_get_mhpmcounter3());
		uart1_puts(", c4: ");
		uart1_printulonglong(csr_get_mhpmcounter4());
		uart1_puts(", c5: ");
		uart1_printulonglong(csr_get_mhpmcounter5());
		uart1_puts(", c6: ");
		uart1_printulonglong(csr_get_mhpmcounter6());
		uart1_puts(", c7: ");
		uart1_printulonglong(csr_get_mhpmcounter7());
		uart1_puts("     \r");
		count++;
		if (count == 400) {
			count = 0;
			asm volatile ("ecall;" :::);
		}
	}

	return 0;
}

__attribute__ ((interrupt, used))
void trap_handler(void) {

	uint32_t mepc = csr_read(mepc);
	mepc += 4;
	csr_write(mepc, mepc);
}
