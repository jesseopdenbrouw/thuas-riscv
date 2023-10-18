#include <thuasrv32.h>

uint32_t i2c1_transmit_byte(uint8_t data)
{
	/* Send data */
	I2C1->DATA = data;

	/* Wait for transmission to end */
	while ((I2C1->STAT & I2C_TC) == 0x00);

	return I2C1->STAT & I2C_AF;
} 
