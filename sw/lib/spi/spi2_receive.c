/*
 * spi2_receive.c -- receive a number of bytes from SPI2
 *
 */

#include <stdint.h>

#include <thuasrv32.h>

/* Receives a array of bytes, while sending dummy bytes */
void spi2_receive(uint8_t *buf, uint32_t len, uint32_t dummy)
{
	for (uint32_t i = 0; i < len; i++) {
		*buf++ = spi2_transfer(dummy);
	}
}
