#include <stdint.h>

#include <thuasrv32.h>

void spi1_transmit_receive(uint8_t *buft, uint8_t *bufr, uint32_t len)
{
	for (uint32_t i = 0; i < len; i++) {
		*bufr++ = spi1_transfer(*buft++);
	}
}
