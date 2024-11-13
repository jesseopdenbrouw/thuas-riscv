/*
 * i2c2_receive.c -- receives a stream ob bytes via I2C2, sends START and STOP bits
 *
 */

#include <thuasrv32.h>

uint32_t i2c2_receive(uint8_t address, uint8_t *buf, uint32_t len)
{
	/* If length is 0 or buffer points to NULL, only transmit address + START + STOP */
	if (len == 0 || buf == NULL) {
		return i2c2_transmit_address_only(address);
	}

	/* Transmit address + START */
	uint32_t ret = i2c2_transmit_address(address);

	/* If error, return */
	if (ret) {
		return ret;
	}

	/* Receive all bytes, first set master ACK */
	I2C2->CTRL |= I2C_MACK;
	for (int i = 0; i < len; i++) {
		/* Set STOP generation on last byte */
		if (i == len-1) {
			I2C2->CTRL |= I2C_STOP;
		}
		/* Transfer byte, return if error */
		*buf++ = i2c2_receive_byte();
	}
	/* Disable master ACK */
	I2C2->CTRL &= ~I2C_MACK;

	return 0;	
}
