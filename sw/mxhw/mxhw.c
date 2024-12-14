/*
 * mxhw.c -- print available hardware
 *
 */

#include <thuasrv32.h>

#ifndef F_CPU
#define F_CPU (50000000UL)
#endif
#ifndef BAUD_RATE
#define BAUD_RATE (9600UL)
#endif

int main(void)
{

	uart1_init(BAUD_RATE, UART_CTRL_EN);

	uint32_t hw = csr_read(0xfc0); // CSR address = 0xfc0
	uint32_t speed = csr_read(0xfc1); // CSR address = 0xfc1
	uint32_t readback;
	int count = 0;

	if (hw == 0) {
		uart1_puts("\r\nHardware signals all zero, CSR probably not enabled\r\n");
		while (1);
	}

	uart1_printf("\r\nHW version:   ");
	printhwversion();
	uart1_printf("\r\nCPU speed is: %d\r\n", speed);

	uart1_printf("\r\nread CSR mxhw: 0x%08x\r\n", hw);

	uart1_printf("has GPIOA: %s\r\n", (hw & CSR_MXHW_GPIOA) ? "yes" : "no");
	uart1_printf("has UART1: %s\r\n", (hw & CSR_MXHW_UART1) ? "yes" : "no");
	uart1_printf("has UART2: %s\r\n", (hw & CSR_MXHW_UART2) ? "yes" : "no");
	uart1_printf("has I2C1: %s\r\n", (hw & CSR_MXHW_I2C1) ? "yes" : "no");
	uart1_printf("has I2C2: %s\r\n", (hw & CSR_MXHW_I2C2) ? "yes" : "no");
	uart1_printf("has SPI1: %s\r\n", (hw & CSR_MXHW_SPI1) ? "yes" : "no");
	uart1_printf("has SPI2: %s\r\n", (hw & CSR_MXHW_SPI2) ? "yes" : "no");
	uart1_printf("has TIMER1: %s\r\n", (hw & CSR_MXHW_TIMER1) ? "yes" : "no");
	uart1_printf("has TIMER2: %s\r\n", (hw & CSR_MXHW_TIMER2) ? "yes" : "no");
	uart1_printf("has multiply/divide: %s\r\n", (hw & CSR_MXHW_MULDIV) ? "yes" : "no");
	uart1_printf("has fast divide: %s\r\n", (hw & CSR_MXHW_FASTDV) ? "yes" : "no");
	uart1_printf("has bootloader: %s\r\n", (hw & CSR_MXHW_BOOT) ? "yes" : "no");
	uart1_printf("has registers in RAM: %s\r\n", (hw & CSR_MXHW_REGRAM) ? "yes" : "no");
	uart1_printf("has Zba extension: %s\r\n", (hw & CSR_MXHW_ZBA) ? "yes" : "no");
	uart1_printf("has Zicond: %s\r\n", (hw & CSR_MXHW_ZICOND) ? "yes" : "no");
	uart1_printf("has Zbs extension: %s\r\n", (hw & CSR_MXHW_ZBS) ? "yes" : "no");
	uart1_printf("UART1 break resets processor: %s\r\n", (hw & CSR_MXHW_BREAK) ? "yes" : "no");
	uart1_printf("has watchdog (WDT): %s\r\n", (hw & CSR_MXHW_WDT) ? "yes" : "no");
	uart1_printf("has Zihpm counters: %s\r\n", (hw & CSR_MXHW_ZIHPM) ? "yes" : "no");
	uart1_printf("has on-chip debugger: %s\r\n", (hw & CSR_MXHW_OCD) ? "yes" : "no");
	uart1_printf("has MSI: %s\r\n", (hw & CSR_MXHW_MSI) ? "yes" : "no");
	uart1_printf("has Buffer I/O reponse: %s\r\n", (hw & CSR_MXHW_BUFFER) ? "yes" : "no");

	/* Are HPM counters enabled... */
	if (hw & CSR_MXHW_ZIHPM) {
		/* Disable all counters, this will disable only the implemented counters */
		csr_write(mcountinhibit, -1);
		/* Read back the implemented counters */
		readback = csr_read(mcountinhibit);
		/* Enable counters */
		csr_write(mcountinhibit, 0);	
		uart1_printf("Hardware performance counters enabled: %08x\r\n", readback);
		/* Test each counter for availability */
		for (int i = 3; i < 32; i++) {
			if (readback & (1 << i)) {
				uart1_printf("%d ", i);
				count++;
			}
		}
		uart1_printf("\r\nTotal number of counters: %d\r\n", count);
		csr_write(mhpmevent3, -1);
		readback = csr_read(mhpmevent3);
		csr_write(mhpmevent3, 0);
		count = 0;
		for (int i = 0; i < 32; i++) {
			if (readback & (1 << i)) {
				uart1_printf("%d ", i);
				count++;
			}
		}
		uart1_printf("\r\nTotal number of events: %d\r\n", count);
	}
	uart1_printf("Done.\r\n");

}
