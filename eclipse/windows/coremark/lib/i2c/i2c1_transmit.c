/*
 * i2c1_transmit.c -- transmit a stream of bytes via I2C1, including a START en STOP bit
 *
 */

#include <thuasrv32.h>

uint32_t i2c1_transmit(uint8_t address, uint8_t *buf, uint32_t len)
{
	/* If length is 0 or buffer is NULL, only transmit address + START + STOP */
	if (len == 0 || buf == NULL) {
		return i2c1_transmit_address_only(address);
	}

	/* Transmit address + START */
	uint32_t ret = i2c1_transmit_address(address);

	/* If error, return */
	if (ret) {
		/* Ack fail, so send STOP */
		I2C1->CTRL |= I2C_HARDSTOP;
		while ((I2C1->STAT & I2C_TC) == 0);
		return ret;
	}

	/* Transmit all bytes */
	for (int i = 0; i < len; i++) {
		/* Set STOP generation on last byte */
		if (i == len-1) {
			I2C1->CTRL |= I2C_STOP;
		}
		/* Transfer byte, return if error */
		ret = i2c1_transmit_byte(*buf++);
		if (ret) {
			/* Ack fail, so send STOP, but only if we already didn't sent it */
			if (i != len-1) {
				I2C1->CTRL |= I2C_HARDSTOP;
				while ((I2C1->STAT & I2C_TC) == 0);
			}
			return ret;
		}
	}

	return 0;	
}
