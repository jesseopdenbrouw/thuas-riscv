#include <stdint.h>

#include <thuasrv32.h>

void spi2_init(uint32_t value)
{
	SPI2->CTRL = value;
}
