#include <thuasrv32.h>

uint32_t i2c1_transmit_address_only(uint8_t address)
{
	/* Set start and stop bit generation */
	I2C1->CTRL |= I2C_START | I2C_STOP;

	/* Send address and R/W bit */
	I2C1->DATA = address;

	/* Wait for transmission to end */
	while ((I2C1->STAT & I2C_TC) == 0x00);

	return I2C1->STAT & I2C_AF;
} 
