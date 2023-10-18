#include <thuasrv32.h>

uint8_t i2c2_receive_byte(void)
{
	/* Send dummy byte */
	I2C2->DATA = 0xff;

	/* Wait for data transmission completed */
	while ((I2C2->STAT & I2C_TC) == 0x00);

	return I2C2->DATA;
} 
