/*
 * spi2_transmit_receive.c -- send and receive buffers via SPI2
 *
 */

#include <stdint.h>

#include <thuasrv32.h>

void spi2_transmit_receive(uint8_t *buft, uint8_t *bufr, uint32_t len)
{
	for (uint32_t i = 0; i < len; i++) {
		*bufr++ = spi2_transfer(*buft++);
	}
}
