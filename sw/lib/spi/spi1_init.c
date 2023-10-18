#include <stdint.h>

#include <thuasrv32.h>

void spi1_init(uint32_t value)
{
	SPI1->CTRL = value;
}
