
/*
 * gpioa_setopendrain.c -- Sets (or resets) open drain output for pins
 */

#include <stdint.h>

#include <thuasrv32.h>

void gpioa_setopendrain(uint32_t pin)
{
	GPIOA->POD = pin;
}
