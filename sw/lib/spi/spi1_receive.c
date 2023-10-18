#include <stdint.h>

#include <thuasrv32.h>

void spi1_receive(uint8_t *buf, uint32_t len, uint32_t dummy)
{
	for (uint32_t i = 0; i < len; i++) {
		*buf++ = spi1_transfer(dummy);
	}
}
