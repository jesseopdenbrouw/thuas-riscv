
/*
 * gpioa_readpin.c -- Read a pin status from GPIOA
 */

#include <stdint.h>

#include <thuasrv32.h>

uint32_t gpioa_readpin(uint32_t pin)
{
	uint32_t pinstatus = (GPIOA->PIN & pin);
	return pinstatus == 0 ? GPIO_PIN_RESET : GPIO_PIN_SET;
}
