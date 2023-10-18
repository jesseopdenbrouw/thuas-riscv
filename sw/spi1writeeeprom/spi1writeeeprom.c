/*
 *
 * spi1writeeeprom
 *
 * Program to write data to the 25AA010A serial EEPROM.
 *
 * This program writes the first few bytes of a 25AA101A
 * bit-serial 128 bytes EEPROM. It writes the buffer `wbuf`
 * to the device, waits for the EEPROM to finish the write,
 * reads the bytes back and prints them on the terminal.
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

/* Defines */
#define EEPROMWRSR  (0x01)
#define EEPROMWRITE (0x02)
#define EEPROMREAD  (0x03)
#define EEPROMWRDI  (0x04)
#define EEPROMRDSR  (0x05)
#define EEPROMWREN  (0x06)
#define ADDRESS (0x00)

int main(void)
{

	/* Buffer with the WRITE command, the address and the data to write.
	 * The 25AA010A can write 16 bytes max in one transfer, on 16-byte
	 * boundaries. */
	uint8_t wbuf[] = { EEPROMWRITE, ADDRESS, 'T', 'e', 's', 't', 0xbe, 0xef, 0xaa, 0xbb };
	uint8_t rbuf[16] = { 0 };

	/* Deactivate device, soft NSS high */
	GPIOA->POUT |= 1<<15;

	/* CS setup, CS hold, /16, 8 bits, mode 0 */
	SPI1->CTRL = (0 << 20) | (0 << 12) | (3<<8) | (0<<4) | (0<<1);

	uart1_init(BAUD_RATE, UART_CTRL_NONE);

	uart1_puts("\r\nWriting EEPROM 25AA010\r\n");

	/* Send the WRITE ENABLE command */
	/* Activate device, soft NSS low */
	GPIOA->POUT &= ~(1<<15);

	/* Send Write Enable code */
	SPI1->DATA = EEPROMWREN; 

	/* Wait for transmission complete */
	while (!(SPI1->STAT & 0x08));

	/* Deactivate device, soft NSS high */
	GPIOA->POUT |= 1<<15;

	/* Send the buffer */
	/* Activate device, soft NSS low */
	GPIOA->POUT &= ~(1<<15);

	/* Write the bytes */
	for (uint32_t byte = 0; byte < sizeof wbuf/sizeof wbuf[0]; byte++) {

		/* Send buffer one at the time */
		SPI1->DATA = wbuf[byte]; 

		/* Wait for transmission complete */
		while (!(SPI1->STAT & 0x08));
	}

	/* Deactivate device, soft NSS high */
	GPIOA->POUT |= 1<<15;

	/* Read in the Status Register and check the WIP bit.
	 * Write In Progress is 1 if write to internal EEPROM
	 * is ongoing, 0 if completed. This takes max 5 ms. */
	do {
		/* Activate device, soft NSS low */
		GPIOA->POUT &= ~(1<<15);

		/* Send RDSR command */
		SPI1->DATA = EEPROMRDSR;

		/* Wait for transmission complete */
		while (!(SPI1->STAT & 0x08));

		/* Send dummy byte to read in response */
		SPI1->DATA = 0x00; 

		/* Wait for transmission complete */
		while (!(SPI1->STAT & 0x08));

		/* Deactivate device, soft NSS high */
		GPIOA->POUT |= 1<<15;

	} while (SPI1->DATA & 0x01);


	/* Activate device, soft NSS low */
	GPIOA->POUT &= ~(1<<15);

	/* Send EEPROMREAD */
	SPI1->DATA = EEPROMREAD; 

	/* Wait for transmission complete */
	while (!(SPI1->STAT & 0x08));

	/* Send address */
	SPI1->DATA = ADDRESS; 

	/* Wait for transmission complete */
	while (!(SPI1->STAT & 0x08));

	/* Read first 16 bytes */
	for (uint32_t addr = 0x00; addr < 0x10; addr++) {

		/* Send dummy */
		SPI1->DATA = 0x00; 

		/* Wait for transmission complete */
		while (!(SPI1->STAT & 0x08));

		/* Read out received data */
		rbuf[addr] = SPI1->DATA;
	}

	/* Deactivate device, soft NSS high */
	GPIOA->POUT |= 1<<15;

	for (uint32_t addr = 0x00; addr < 0x10; addr++) {
		/* Print out address and data */
		uart1_puts("Address: 0x");
		printhex((ADDRESS + addr) & 0xff, 2);
		uart1_puts(" = 0x");
		printhex(rbuf[addr], 2);
		uart1_puts("\r\n");
	}

	uart1_puts("Done.\r\n");

	while(1);
}
