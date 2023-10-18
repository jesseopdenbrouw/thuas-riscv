/*
 *
 * i2c1findslaves -- find slaves on the I2C bus
 *
 * This program searches for connected I2C slaves on the bus
 *
 *
 */

#include <stdio.h>
#include <stdint.h>

#include <thuasrv32.h>

#ifndef F_CPU
#define F_CPU (50000000UL)
#endif
#ifndef BAUD_RATE
#define BAUD_RATE (9600UL)
#endif


int main(void)
{
	char buffer[20];

	uart1_init(BAUD_RATE, UART_CTRL_NONE);

	uart1_puts("\r\nI2C1 find slaves\r\n");

	/* Standard mode (Sm), 100 kHz */
	i2c1_init(I2C_PRESCALER_SM(csr_read(0xfc1)));

	for (uint32_t i = 0x01; i < 0x78; i++) {

		if (i2c1_transmit(i << 1, NULL, 0) != 0) {
			//	uart1_puts("ACK failed!\r\n");
		} else {
			/* Print out the data */
			uart1_puts("Slave found at address: ");
			snprintf(buffer, sizeof buffer, "0x%02lx\r\n", i);
			uart1_puts(buffer);
		}

		for (volatile uint32_t i = 0; i < 500; i++);
	}

	uart1_puts("Done\r\n");
	while (1) {}
}

