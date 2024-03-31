/*
 * i2c1_init -- initialize I2C1 hardware
 *
 */

#include <thuasrv32.h>

void i2c1_init(uint32_t val)
{
	I2C1->CTRL = val;
}
