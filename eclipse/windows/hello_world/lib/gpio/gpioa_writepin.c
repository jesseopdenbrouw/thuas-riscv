
/*
 * gpioa_writepin.c -- Write a pin status to GPIOA
 */

#include <stdint.h>

#include <thuasrv32.h>

void gpioa_writepin(uint32_t pin, uint32_t value)
{
	if (value == GPIO_PIN_RESET) {
		GPIOA->POUT &= ~pin;
	} else {
		GPIOA->POUT |= pin;
	}
}
