#include <stdint.h>

#include <thuasrv32.h>

uint32_t spi2_transfer(uint32_t data)
{
	/* Send the data */
	SPI2->DATA = data;

	/* Wait for transmission complete */
	while (!(SPI2->STAT & 0x08));

	/* Return received data */
	return SPI2->DATA;
}
