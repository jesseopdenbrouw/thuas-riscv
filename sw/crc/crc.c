/*
 * Testing the CRC unit, poly is CRC32/BZIP2.
 */

#include <thuasrv32.h>

#include <stdio.h>

/* Frequency of the DE0-CV board */
#ifndef F_CPU
#define F_CPU (50000000UL)
#endif
/* Transmission speed */
#ifndef BAUD_RATE
#define BAUD_RATE (115200ULL)
#endif



int main(void)
{

	uint32_t poly = 0x04c11db7;
	//uint32_t poly = 0xedb88320;
	uint32_t sreg_init = 0xffffffff;
	char message[] = "Dit is een bericht";
	uint32_t check;
	char buf[60];

	uart1_init(BAUD_RATE, UART_CTRL_EN);

	if ((csr_read(0xfc0) & CSR_MXHW_CRC) == 0) {
		uart1_puts("CRC unit is not installed in hardware!\r\n");
		while (1);
	}

	uart1_puts("Calculating CRC-32/BZIP2 for byte and string\r\n");

	/* Initialize CRC unit */
	crc_init(CRC_SIZE32, poly, sreg_init);
	/* Write one 0xff */
	crc_write(0xff);
	/* Get CRC */
	check = crc_get();

	snprintf(buf, sizeof buf, "Write 1 byte: 0xff, CRC check: 0x%08lx\r\n", check);
	uart1_puts(buf);

	/* Initialize CRC unit */
	crc_init(CRC_SIZE32, poly, sreg_init);
	/* CRC calculations on a block of bytes */
	crc_block((uint8_t *) message, sizeof message - 1); /* Skip the trailing \0 */
	/* Get CRC */
	check = crc_get();

	uart1_puts("Message: ");
	uart1_puts(message);
	snprintf(buf, sizeof buf, "\r\nCRC check: 0x%08lx\r\n", check);
	uart1_puts(buf);

	uart1_puts("For CRC32/BZIP2, the final CRC outcome must be inverted\r\n");

	while(1);
}

