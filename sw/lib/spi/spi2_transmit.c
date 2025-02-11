/*
 * spi2_transmit.c -- send a buffer via SPI2
 *
 */

#include <stdint.h>

#include <thuasrv32.h>

void spi2_transmit(uint8_t *buf, uint32_t len)
{
	for (uint32_t i = 0; i < len; i++) {
		spi2_transfer(*buf++);
	}
}
