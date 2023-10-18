#include <thuasrv32.h>

uint8_t i2c1_receive_byte(void)
{
	/* Send dummy byte */
	I2C1->DATA = 0xff;

	/* Wait for data transmission completed */
	while ((I2C1->STAT & I2C_TC) == 0x00);

	return I2C1->DATA;
} 
