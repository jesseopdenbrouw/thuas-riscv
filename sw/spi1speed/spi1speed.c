/*
 *
 * spi1speed
 *
 * Program to read data from the 25AA010A serial EEPROM
 *
 * This program reads the first 16 bytes from the EEPROM and
 * displays them on the terminal program (e.g. PuTTY) using
 * UART1. The program writes a 24-bit datum, with instruction
 * code and address and a dummy byte. During this 24-bit write
 * the data from the EEPROM is read. In the least significant
 * byte is the data from the EEPROM. The EEPROM can work in
 * mode 0 and mode 3.
 *
 * This version reads in the data from the EEPROM at full
 * speed. Used to test the SPI hardware.
 *
 */

#include <stdint.h>
#include <ctype.h>

#include <thuasrv32.h>

/* Should be loaded by the Makefile */
#ifndef F_CPU
#define F_CPU (50000000UL)
#endif
#ifndef BAUD_RATE
#define BAUD_RATE (9600UL)
#endif

#define EEPROMREAD (0x03)

int main(void)
{

	/* CS setup, CS hold, /16, 24 bits, mode 0 */
    spi1_init(SPI_CSSETUP(9) |
              SPI_CSHOLD(9)  |
              SPI_PRESCALER3 |
              SPI_SIZE24     |
              SPI_MODE0);

	uart1_init(BAUD_RATE, UART_CTRL_NONE);
	uart1_puts("\r\n");

	while (1) {
		/* Buffer */
		char buf[20] = { 0 };

		/* Read first 16 bytes */
		for (uint32_t addr = 0x00; addr < 0x10; addr++) {

			/* EEPROMREAD + addr + dummy */
			/* During dummy, data is read from addr */
			buf[addr] = (char) spi1_transfer((EEPROMREAD << 16) | (addr << 8));
		}

		uart1_puts("Address 0x00: ");
		uart1_puts(buf);
		uart1_puts("\r");
	
	}

	return 0;
}
