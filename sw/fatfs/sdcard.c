/*
 *
 * SD Card Communication for THUAS RISC-V processor
 * Used on the Terasic DE0-CV board
 *
 * Based on: http://rjhcoding.com/avrc-sd-interface-1.php
 *
 */

#include <stdint.h>
#include <ctype.h>
#include <stdio.h>
#include <string.h>

#include <thuasrv32.h>
#include "sdcard.h"

/* Should be loaded by the Makefile */
#ifndef F_CPU
#define F_CPU (50000000UL)
#endif
#ifndef BAUD_RATE
#define BAUD_RATE (9600UL)
#endif

/* SPI speed in system clocks / (2^(x+1)) */
/* 7 = /256, 3 = /16 */
#define SD_SLOW  (7)
#define SD_FAST  (3)

#define SD_DEBUG (0)

/* Read time out = 100 ms, write timeout = 250 ms */
/* As per SDC specification */
#define SD_READ_TIMEOUT ((F_CPU/10)/((1<<(SD_FAST+1))*8))
#define SD_WRITE_TIMEOUT ((F_CPU/4)/((1<<(SD_FAST+1))*8))

/* Local variables with info */
static struct {
	 uint32_t version;
	 uint32_t capacity;
	 uint16_t speed;
} csd;

static struct {
	 uint16_t sectorsize;
	 uint16_t ccs;
	 uint16_t status;
} ocr;

static struct {
	 uint16_t mid;
	 uint16_t mdt;
	 uint8_t prv;
	 char oid[3];
	 char pnm[6];
	 uint32_t psn;
} cid;

/*
 * SPI2 basic transfer commands
 */
/* Set transmissio speed */
void SPI2_init(uint32_t speed)
{
	/* /256, 8 bits, mode 0 */
	SPI2->CTRL = speed<<8;
}

/* Activate low Chip Select */
void SPI2_csenable(void)
{
	GPIOA->POUT &= ~(1<<14);
}

/* Deactivate high Chip Select */
void SPI2_csdisable(void)
{
	GPIOA->POUT |= 1<<14;
}

/* Transfer 1 byte to SPI2 */
uint8_t SPI2_transfer(uint8_t what)
{
	/* Send data */
	SPI2->DATA = (uint32_t) what;

	/* Wait for transmission complete */
	while (!(SPI2->STAT & 0x08));

	/* Return data */
	return SPI2->DATA & 0xff;
}

/*
 * SD commands
 */
/* Power up SD card */
void SD_powerup()
{
	/* make sure card is deselected */
	SPI2_csdisable();

	/* give SD card time to power up */
	for (volatile uint32_t i; i < 10000; i++);

	/* send 80 clock cycles to synchronize */
	/* Should be at least 74 clocks as per spec */
	for (uint32_t i = 0; i < 10; i++) {
		SPI2_transfer(0xff);
	}

	/* deselect SD card */
	SPI2_csdisable();
	SPI2_transfer(0xff);
}

/* Transfer a command to the SD card */
/* CS must be enabled */
void SD_command(uint8_t cmd, uint32_t arg, uint8_t crc)
{
	/* transmit command to sd card */
	SPI2_transfer(cmd|0x40);

	/* transmit argument */
	SPI2_transfer((arg >> 24) & 0xff);
	SPI2_transfer((arg >> 16) & 0xff);
	SPI2_transfer((arg >>  8) & 0xff);
	SPI2_transfer((arg >>  0) & 0xff);

	/* transmit crc */
	SPI2_transfer(crc);
}

/* Read R1 response */
uint8_t SD_readR1(void)
{
	uint8_t i, ret;
	//char buf[30];

	/* keep polling until actual data received */
	/* but not more than 8 times as per spec */
	for (i = 0; ((ret = SPI2_transfer(0xff)) == 0xff) && i < 9; i++);

	return ret;
}

#if SD_DEBUG == 1

/* Print R1 response */
void SD_printR1(uint8_t r1)
{
	uart1_puts("R1 status: ");
	if (r1 & 0x80) {
		uart1_puts("MSB = 1\r\n");
		return;
	}
	if (r1 == 0x00) {
		uart1_puts("Card ready\r\n");
		return;
	}

	if (r1 & 0x40) {
		uart1_puts("Parameter ");
	}
	if (r1 & 0x20) {
		uart1_puts("Address ");
	}
	if (r1 & 0x10) {
		uart1_puts("Erase seq");
	}
	if (r1 & 0x08) {
		uart1_puts("CRC ");
	}
	if (r1 & 0x04) {
		uart1_puts("Illegal ");
	}
	if (r1 & 0x02) {
		uart1_puts("Erase reset ");
	}
	if (r1 & 0x01) {
		uart1_puts("Idle");
	}
	uart1_puts("\r\n");
}

#endif

/* Send CMD 0 to SD card */
uint8_t SD_CMD0(void)
{
	/* Enable chip select */
	SPI2_transfer(0xff);
	SPI2_csenable();;
	SPI2_transfer(0xff);

	/* send CMD0 */
	SD_command(0, 0x00000000, 0x95);

	/* read response */
	uint8_t ret = SD_readR1();

	/* Disable chip select */
	SPI2_transfer(0xff);
	SPI2_csdisable();
	SPI2_transfer(0xff);

	return ret;
}

/* Read R3 or R7 reponse */
void SD_readR37(uint8_t *res)
{
	// read response 1 in R7
	res[0] = SD_readR1();

	// if error reading R1, return
	if (res[0] > 1) {
		return;
	}

	// read remaining bytes
	res[1] = SPI2_transfer(0xff);
	res[2] = SPI2_transfer(0xff);
	res[3] = SPI2_transfer(0xff);
	res[4] = SPI2_transfer(0xff);
}

/* Send CMD8 to SD card */
void SD_CMD8(uint8_t *res)
{
	// assert chip select
	SPI2_transfer(0xff);
	SPI2_csenable();
	SPI2_transfer(0xff);

	// send CMD8
	SD_command(8, 0x000001aa, 0x87);

	// read response
	SD_readR37(res);

	// deassert chip select
	SPI2_transfer(0xff);
	SPI2_csdisable();
	SPI2_transfer(0xff);
}

/* Send CMD58 to SD card */
void SD_CMD58(uint8_t *res)
{
	// assert chip select
	SPI2_transfer(0xff);
	SPI2_csenable();
	SPI2_transfer(0xff);

	// send CMD58
	SD_command(58, 0x00000000, 0xff);

	// read response
	SD_readR37(res);

	// deassert chip select
	SPI2_transfer(0xff);
	SPI2_csdisable();
	SPI2_transfer(0xff);
}

#if SD_DEBUG == 1

/* Print R3 response */
void SD_printR3(uint8_t *res)
{
	SD_printR1(res[0]);

	if (res[0] > 1) {
		return;
	}

	uart1_puts("Card Power Up Status: ");
	if (res[1] & 0x80) {
		uart1_puts("READY\r\n");
		uart1_puts("CCS Status: ");
	        if (res[1] & 0x40) {
			uart1_puts("1\r\n");
	       	} else {
			uart1_puts("0\r\n");
		}
	} else {
		uart1_puts("BUSY\r\n");
	}

	uart1_puts("VDD Window: ");
	if (res[3] & 0x80) { uart1_puts("2.7-2.8, "); }
	if (res[2] & 0x01) { uart1_puts("2.8-2.9, "); }
	if (res[2] & 0x02) { uart1_puts("2.9-3.0, "); }
	if (res[2] & 0x04) { uart1_puts("3.0-3.1, "); }
	if (res[2] & 0x08) { uart1_puts("3.1-3.2, "); }
	if (res[2] & 0x10) { uart1_puts("3.2-3.3, "); }
	if (res[2] & 0x20) { uart1_puts("3.3-3.4, "); }
	if (res[2] & 0x40) { uart1_puts("3.4-3.5, "); }
	if (res[2] & 0x80) { uart1_puts("3.5-3.6"); }
	uart1_puts("\r\n");
}

#endif

/* Send CMD55 to SD card */
/* Prefix for ACMD41 */
uint8_t SD_CMD55(void)
{
	// assert chip select
	SPI2_transfer(0xff);
	SPI2_csenable();
	SPI2_transfer(0xff);

	// send CMD55
	SD_command(55, 0x00000000, 0xff);

	// read response
	uint8_t ret = SD_readR1();

	// deassert chip select
	SPI2_transfer(0xff);
	SPI2_csdisable();
	SPI2_transfer(0xff);

	return ret;
}

/* Send ACMD41 to SD card */
/* Needs CMD55 first */
uint8_t SD_ACMD41(void)
{
	// assert chip select
	SPI2_transfer(0xff);
	SPI2_csenable();
	SPI2_transfer(0xff);

	// send ACMD41
	// arg = 0x40000000 = support High Capacity Cards
	SD_command(41, 0x40000000, 0xff);

	// read response
	uint8_t ret = SD_readR1();

	// deassert chip select
	SPI2_transfer(0xff);
	SPI2_csdisable();
	SPI2_transfer(0xff);

	return ret;
}

/* Get CSD */
uint32_t SD_CMD910(uint8_t cmd, uint8_t *buf)
{
#if SD_DEBUG == 1
	char buffer[40];
#endif
	uint32_t count;

	// assert chip select
	SPI2_transfer(0xff);
	SPI2_csenable();
	SPI2_transfer(0xff);

	// send CMD9 or CMD10
	SD_command(cmd, 0x00000000, 0xff);

	// read response first byte
	uint8_t ret = SD_readR1();
#if SD_DEBUG == 1
	snprintf(buffer, sizeof buffer, "CMD%d responded: 0x%02x\r\n", cmd, ret);
	uart1_puts(buffer);
#endif
	if (ret != 0x00) {
		return SD_ERROR;
	}

	/* Wait while idle */
	count = SD_READ_TIMEOUT;
	while ((ret = SPI2_transfer(0xff)) == 0xff) {
		count--;
		if (count == 0) {
			// deassert chip select
			SPI2_transfer(0xff);
			SPI2_csdisable();
			SPI2_transfer(0xff);
#if SD_DEBUG == 1
			uart1_puts("Timeout reached on transport!\r\n");
#endif
		}
	}
#if SD_DEBUG == 1
	snprintf(buffer, sizeof buffer, "CMD%d count: %lu\r\n", cmd, count);
	uart1_puts(buffer);
	snprintf(buffer, sizeof buffer, "CMD%d transport token: 0x%02x\r\n", cmd, ret);
	uart1_puts(buffer);
#endif
	if (ret != 0xfe) {
		return SD_ERROR;
	}

	// Read the bytes
	for (int i = 0; i < 16; i++) {
		buf[i] = SPI2_transfer(0xff);
	}

	// Gobble CRC
	SPI2_transfer(0xff);
	SPI2_transfer(0xff);

	// deassert chip select
	SPI2_transfer(0xff);
	SPI2_csdisable();
	SPI2_transfer(0xff);

#if SD_DEBUG == 1
	//uart1_puts("Data: ");
	for (int i = 0; i < 16; i++) {
		snprintf(buffer, sizeof buffer, "%02x ", buf[i]);
		uart1_puts(buffer);
	}
#endif

	return SD_SUCCESS;
}

/* Extract bits from CSD or CID command response */
/* https://os.mbed.com/users/mbed_official/code/SDFileSystem//file/8db0d3b02cec/SDFileSystem.cpp */
static uint32_t ext_bits(uint8_t *data, uint32_t msb, uint32_t lsb) {
	uint32_t bits = 0;
	uint32_t size = 1 + msb - lsb;
	for (uint32_t i = 0; i < size; i++) {
		uint32_t position = lsb + i;
		uint32_t byte = 15 - (position >> 3);
		uint32_t bit = position & 0x7;
		uint32_t value = (data[byte] >> bit) & 1;
		bits |= value << i;
	}
	return bits;
}

/* Initialize SD card */
uint32_t SD_initialize(void) {

#if SD_DEBUG == 1
	char buffer[40] = { 0 };
#endif
	uint8_t res[6] = { 0 };
	uint32_t counter;
	uint8_t csdcid[16];

	/* Clear data structs */
	memset((void *) &csd, 0, sizeof csd);
	memset((void *) &ocr, 0, sizeof ocr);
	memset((void *) &cid, 0, sizeof cid);

	/* Slowest speed: /256 */
	SPI2_init(SD_SLOW);

	/* Power up SD card */
	SD_powerup();

	/* Go to Idle state */
	res[0] = SD_CMD0();
#if SD_DEBUG == 1
	/* Print status from SD */
	uart1_puts("Go Idle: ");
	SD_printR1(res[0]);
#endif
	if (res[0] > 1) {
		return SD_ERROR;
	}

	/* Get IF conditions */
	SD_CMD8(res);
#if SD_DEBUG == 1
	uart1_puts("IF Conditions: ");
	SD_printR1(res[0]);
	snprintf(buffer, sizeof buffer, "IF Conditions: Echo: %02x\r\n", res[4]);
	uart1_puts(buffer);
#endif
	if (res[0] > 1) {
		return SD_ERROR;
	}

	/* CMD55 / ACMD41 */
	for (counter = 100; counter > 0; counter--) {
		res[0] = SD_CMD55();
#if SD_DEBUG == 1
		uart1_puts("APP cmd: ");
		SD_printR1(res[0]);
#endif
		if (res[0] > 1) {
			return SD_ERROR;
		}
		res[0] = SD_ACMD41();
#if SD_DEBUG == 1
		uart1_puts("Operation conditions: ");
		SD_printR1(res[0]);
#endif
		if (res[0] > 1) {
			return SD_ERROR;
		}
		if (res[0] == 0x00) {
			break;
		}
	}

	if (counter == 0) {
#if SD_DEBUG == 1
		uart1_puts("CMD55/ACMD41 failed!\r\n");
#endif
		return SD_ERROR;
	}

	SD_CMD58(res);
#if SD_DEBUG == 1
	uart1_puts("Get OCR: ");
	SD_printR3(res);
#endif
	if (res[0] > 1) {
		return SD_ERROR;
	}

	/* Check capacity */
	if ((res[1] & 0xc0) == 0xc0) {
		ocr.ccs = 1;
		ocr.sectorsize = 512;
	} else if ((res[1] & 0xc0) == 0x80) {
		ocr.ccs = 0;
		ocr.sectorsize = 1;
	}
#if SD_DEBUG == 1
	snprintf(buffer, sizeof buffer, "CCS = %u, sectorsize = %u\r\n", ocr.ccs, ocr.sectorsize);
	uart1_puts(buffer);
#endif
	if ((res[1] & 0x80) == 0x00) {
		/* Card not ready, return error */
		return SD_ERROR;
	}

	/* Switch to fast access: Clock /4 */
	SPI2_init(SD_FAST);

	/* Get CSD (CMD9) */
#if SD_DEBUG == 1
	uart1_puts("Getting CSD... ");
#endif
	if (SD_CMD910(9, csdcid) == SD_SUCCESS) {
#if SD_DEBUG == 1
		uart1_puts("success\r\n");
#endif
	} else {
#if SD_DEBUG == 1
		uart1_puts("error\r\n");
#endif
		return SD_ERROR;
	}
	csd.version = ext_bits(csdcid, 127, 126) + 1;
#if SD_DEBUG == 1
	snprintf(buffer, sizeof buffer, "CSD version: %lu\r\n", csd.version);
	uart1_puts(buffer);
#endif
	csd.capacity = (ext_bits(csdcid, 69, 48)+1);
#if SD_DEBUG == 1
	snprintf(buffer, sizeof buffer, "Card size: %lu\r\n", csd.capacity);
	uart1_puts(buffer);
#endif
	csd.speed = ext_bits(csdcid, 103, 96);
#if SD_DEBUG == 1
	snprintf(buffer, sizeof buffer, "Card speed: 0x%02x\r\n", csd.speed);
	uart1_puts(buffer);
#endif

	/* Get CID (CMD10) */
#if SD_DEBUG == 1
	uart1_puts("Getting CID... ");
#endif
	if (SD_CMD910(10, csdcid) == SD_SUCCESS) {
#if SD_DEBUG == 1
		uart1_puts("success\r\n");
#endif
	} else {
#if SD_DEBUG == 1
		uart1_puts("error\r\n");
#endif
		return SD_ERROR;
	}
	cid.mid = csdcid[0];
	cid.oid[0] = csdcid[1];
	cid.oid[1] = csdcid[2];
	cid.oid[2] = '\0';
	cid.pnm[0] = csdcid[3];
	cid.pnm[1] = csdcid[4];
	cid.pnm[2] = csdcid[5];
	cid.pnm[3] = csdcid[6];
	cid.pnm[4] = csdcid[7];
	cid.pnm[5] = '\0';
	cid.prv = csdcid[8];
	cid.psn = ext_bits(csdcid, 55, 24);
	cid.mdt = ext_bits(csdcid, 19, 8);
#if SD_DEBUG == 1
	snprintf(buffer, sizeof buffer, "Manufacturer ID: 0x%02x\r\n", cid.mid);
	uart1_puts(buffer);
	snprintf(buffer, sizeof buffer, "OEM ID: %s\r\n", cid.oid);
	uart1_puts(buffer);
	snprintf(buffer, sizeof buffer, "Product name: %s\r\n", cid.pnm);
	uart1_puts(buffer);
	snprintf(buffer, sizeof buffer, "Product revision (BCD): 0x%02x\r\n", cid.prv);
	uart1_puts(buffer);
	snprintf(buffer, sizeof buffer, "Product serial: 0x%08lx\r\n", cid.psn);
	uart1_puts(buffer);
	snprintf(buffer, sizeof buffer, "Manufacturing date: 0x%04x\r\n", cid.mdt);
	uart1_puts(buffer);
#endif

	ocr.status = 1;
	return SD_SUCCESS;
}

/* Read a sector of 512 bytes */
uint32_t SD_readsector(uint32_t sector, uint8_t *buf)
{
#if SD_DEBUG == 1
	char buffer[30];
#endif
	uint8_t ret = 0xff;
	uint32_t count;

	// assert chip select
	SPI2_transfer(0xff);
	SPI2_csenable();
	SPI2_transfer(0xff);

#if SD_DEBUG == 1
	snprintf(buffer, sizeof buffer, "Reading sector %lu ... ", sector);
	uart1_puts(buffer);
#endif

	// send CMD17
	SD_command(17, sector, 0xff);

	ret = SD_readR1();
	if (ret > 1) {
		// deassert chip select
		SPI2_transfer(0xff);
		SPI2_csdisable();
		SPI2_transfer(0xff);
#if SD_DEBUG == 1
		uart1_puts("Error reading sector!\r\n");
#endif
		return SD_ERROR;
	}
#if SD_DEBUG == 1
	uart1_puts("CMD17 accepted, ");
#endif

	/* Wait for token */
	count = SD_READ_TIMEOUT;
	while ((ret = SPI2_transfer(0xff)) == 0xff) {
		count--;
		if (count == 0) {
			break;
		}
	}
#if SD_DEBUG == 1
	snprintf(buffer, sizeof buffer, "count = %ld, token = %02x", count, ret);
	uart1_puts(buffer);
#endif

	if (count == 0) {
		return SD_ERROR;
	}

	/* Read in the sector of 512 bytes */
	for (int i = 0; i < ocr.sectorsize; i++) {
		buf[i] = SPI2_transfer(0xff);
	}

	// Gobble CRC
	SPI2_transfer(0xff);
	SPI2_transfer(0xff);

	// deassert chip select
	SPI2_transfer(0xff);
	SPI2_csdisable();
	SPI2_transfer(0xff);

#if SD_DEBUG == 1
	for (int i = 0; i < 512; i++) {
		if (i % 16 == 0) {
			uart1_puts("\r\n");
		}
		snprintf(buffer, sizeof buffer, "%02x ", buf[i]);
		uart1_puts(buffer);
	}
	uart1_puts("\r\n");
#endif
	return SD_SUCCESS;
}

/* Write a sector of 512 bytes */
uint32_t SD_writesector(uint32_t sector, const uint8_t *buf)
{
#if SD_DEBUG == 1
	char buffer[30];
#endif
	uint8_t ret = 0xff;
	uint32_t count;

	// assert chip select
	SPI2_transfer(0xff);
	SPI2_csenable();
	SPI2_transfer(0xff);

#if SD_DEBUG == 1
	snprintf(buffer, sizeof buffer, "Writing sector %lu ... ", sector);
	uart1_puts(buffer);
#endif

	// send CMD24
	SD_command(24, sector, 0xff);

	ret = SD_readR1();
	if (ret > 1) {
		// deassert chip select
		SPI2_transfer(0xff);
		SPI2_csdisable();
		SPI2_transfer(0xff);
#if SD_DEBUG == 1
		uart1_puts("Error writing sector!\r\n");
#endif
		return SD_ERROR;
	}
#if SD_DEBUG == 1
	uart1_puts("CMD24 accepted, ");
#endif
	/* Write start token 0xFE */
	SPI2_transfer(0xfe);

	/* Send buffer to SD card */
	for (uint32_t i = 0; i < ocr.sectorsize; i++) {
		SPI2_transfer(buf[i]);
	}

	/* Write 2 dummy bytes */
	SPI2_transfer(0xff);
	SPI2_transfer(0xff);

	/* Wait for token */
	count = SD_WRITE_TIMEOUT;
	while ((ret = SPI2_transfer(0xff)) == 0xff) {
		count--;
		if (count == 0) {
			break;
		}
	}
#if SD_DEBUG == 1
	snprintf(buffer, sizeof buffer, "count = %ld, token = %02x, ", count, ret);
	uart1_puts(buffer);
#endif
	if (count == 0) {
		return SD_ERROR;
	}
	
	if ((ret & 0x1f) == 0x05) {
#if SD_DEBUG == 1
		uart1_puts("Data accepted!\r\n");
#endif
		/* Success, wait for card to store data */
		count = SD_WRITE_TIMEOUT;
		while (SPI2_transfer(0xff) == 0x00) {
			count--;
			if (count == 0) {
				// deassert chip select
				SPI2_transfer(0xff);
				SPI2_csdisable();
				SPI2_transfer(0xff);
#if SD_DEBUG == 1
				uart1_puts("Error timeout\r\n");
#endif
				return SD_ERROR;
			}
		}

	} else if ((ret & 0x1f) == 0x0b) {
		/* CRC error, cannot happen on SPI */
	} else if ((ret & 0x1f) == 0x0d) {
		/* Data rejected due to write error */
		// deassert chip select
#if SD_DEBUG == 1
		uart1_puts("Data rejected due to write error\r\n");
#endif
		SPI2_transfer(0xff);
		SPI2_csdisable();
		SPI2_transfer(0xff);
		return SD_ERROR;
	}

	// deassert chip select
	SPI2_transfer(0xff);
	SPI2_csdisable();
	SPI2_transfer(0xff);

	return SD_SUCCESS;
}

uint32_t SD_getsectorsize(void) {
	return ocr.sectorsize;
}
uint32_t SD_getcapacity(void){
	return csd.capacity;
}
uint32_t SD_getccs(void) {
	return ocr.ccs;
}
uint32_t SD_getspeed(void) {
	return csd.speed;
}
uint32_t SD_getcsdver(void) {
	return csd.version;
}
uint32_t SD_getstatus(void) {
	return ocr.status;
}

