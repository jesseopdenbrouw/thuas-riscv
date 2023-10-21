#include <stdint.h>

#include <thuasrv32.h>

int main(void)
{

	uart1_init(BAUD_RATE, UART_CTRL_NONE);

	uint32_t hw = csr_read(0xfc0); // CSR address = 0xfc0
	uint32_t speed = csr_read(0xfc1); // CSR address = 0xfc1
	uint32_t hwid = csr_read(mimpid);

	if (hw == 0) {
		uart1_puts("\r\nHardware signals all zero, CSR probably not enabled\r\n");
		while (1);
	}

	uart1_printf("\r\nHW version:   %08x\r\n", hwid);
	uart1_printf("CPU speed is: %d\r\n", speed);

	uart1_printf("\r\nread CSR mxhw: 0x%08x\r\n", hw);

	uart1_printf("has GPIOA: %s\r\n", (hw & CSR_MXHW_GPIOA) ? "yes" : "no");
	uart1_printf("has UART1: %s\r\n", (hw & CSR_MXHW_UART1) ? "yes" : "no");
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
	uart1_printf("has fast store: %s\r\n", (hw & CSR_MXHW_FASTSTORE) ? "yes" : "no");
	uart1_printf("Done.\r\n");

}
