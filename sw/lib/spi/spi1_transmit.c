/*
 * spi1_transmit.c -- send a buffer via SPI1
 *
 */

#include <stdint.h>

#include <thuasrv32.h>

void spi1_transmit(uint8_t *buf, uint32_t len)
{
	for (uint32_t i = 0; i < len; i++) {
		spi1_transfer(*buf++);
	}
}
