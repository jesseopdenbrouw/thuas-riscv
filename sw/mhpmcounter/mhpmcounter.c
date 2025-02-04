#include <stdio.h>
#include <stdint.h>

#include <thuasrv32.h>

#ifndef F_CPU
#define F_CPU (50000000UL)
#endif
#ifndef BAUD_RATE
#define BAUD_RATE (115200UL)
#endif

void trap_handler(void);

int main(int argc, char *argv[])
{
	uint32_t count = 0;

	uart1_init(BAUD_RATE, UART_CTRL_EN);

	set_mtvec(trap_handler, TRAP_DIRECT_MODE);

	csr_write(mhpmevent3, CSR_HPM_JUMP);
	csr_write(mhpmevent4, CSR_HPM_STALLS);
	csr_write(mhpmevent5, CRR_HPM_STORES);
	csr_write(mhpmevent6, CSR_HPM_LOADS);
	csr_write(mhpmevent7, CSR_HPM_ECALLS);
	csr_write(mhpmevent8, CSR_HPM_EBREAKS);
	csr_write(mhpmevent9, CSR_HPM_MULDIV);

	uart1_puts("c3 counts branch/jump\r\n");
	uart1_puts("c4 counts stall cycles\r\n");
	uart1_puts("c5 counts stores\r\n");
	uart1_puts("c6 counts loads\r\n");
	uart1_puts("c7 counts ECALLs\r\n");
	uart1_puts("c8 counts EBREAKs\r\n");
	uart1_puts("c9 counts multiply/divides\r\n");

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
		uart1_puts(", c8: ");
		uart1_printulonglong(csr_get_mhpmcounter8());
		uart1_puts(", c9: ");
		uart1_printulonglong(csr_get_mhpmcounter9());
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
