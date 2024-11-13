/*
 * i2c2_transmit_address -- transmit address via I2C2, including START bit
 *
 */

#include <thuasrv32.h>

uint32_t i2c2_transmit_address(uint8_t address)
{
	/* Set start bit generation */
	I2C2->CTRL |= I2C_START;

	/* Send address and R/W bit */
	I2C2->DATA = address;

	/* Wait for transmission to end */
	while ((I2C2->STAT & I2C_TC) == 0x00);

	return I2C2->STAT & I2C_AF;
} 
