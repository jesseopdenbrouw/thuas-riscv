#include <stdint.h>

#include <thuasrv32.h>

uint32_t spi1_transfer(uint32_t data)
{
	/* Send the data */
	SPI1->DATA = data;

	/* Wait for transmission complete */
	while (!(SPI1->STAT & 0x08));

	/* Return received data */
	return SPI1->DATA;
}
