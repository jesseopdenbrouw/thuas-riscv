/*
 * i2c1_init -- initialize I2C2 hardware
 *
 */

#include <thuasrv32.h>

void i2c2_init(uint32_t val)
{
	I2C2->CTRL = val;
}
