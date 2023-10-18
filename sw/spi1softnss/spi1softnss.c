/*
 *
 * spi1softnss
 *
 * Program to read data from the 25AA010A serial EEPROM
 *
 * The program uses a software NSS (Chip Select) signal,
 * connected to POUTA pin 15. First, an 8-bit EEPROMREAD
 * code is send. Data is received, but is discarded.
 * Then an 8-bit address is send, and the received data
 * is discarded. Last, an 8-bit dummy (0x00) is send.
 * During the sending of the dummy, the 25AA010A transmits
 * the contents of the address, and this value is printed
 * to the USART. This version uses software generated NSS.
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

/* Override the weak library function */
void spi1_csenable(void)
{
	GPIOA->POUT &= ~(1<<15);
}

/* Override the weak library function */
void spi1_csdisable(void)
{
	GPIOA->POUT |= 1<<15;
}

int main(void)
{

	/* Deactivate device, soft NSS high */
	spi1_csdisable();

	/* CS setup, CS hold, /16, 8 bits, mode 0 */
    spi1_init(SPI_CSSETUP(0) |
              SPI_CSHOLD(0)  |
              SPI_PRESCALER3 |
              SPI_SIZE8      |
              SPI_MODE0);


	uart1_init(BAUD_RATE, UART_CTRL_NONE);

	uart1_puts("\r\n");

	while (1) {
		/* Read first 16 bytes */
		for (uint32_t addr = 0x00; addr < 0x10; addr++) {

			/* Activate device, soft NSS low */
			spi1_csenable();

			/* Send EEPROMREAD */
			spi1_transfer(EEPROMREAD);

			/* Send address */
			spi1_transfer(addr);

			/* Send dummy */
			uint32_t read = spi1_transfer(0xff);

			/* Deactivate device, soft NSS high */
			spi1_csdisable();

			/* Print out address, data and ASCII char */
			uart1_puts("Address: 0x");
			printhex(addr & 0xff, 2);
			uart1_puts(" = 0x");
			printhex(read, 2);
			uart1_puts(" ASCII: ");
			if (read >= 32 && read < 127) {
				uart1_putc((int) (read & 0xff));
			} else {
				uart1_putc('.');
			}
			uart1_puts("\r\n");
	
			/* Simple delay */
			for (volatile uint32_t i = 0; i < 5000000; i++);
		}
		uart1_puts("-----------------------------\r\n");
	}

	return 0;
}
