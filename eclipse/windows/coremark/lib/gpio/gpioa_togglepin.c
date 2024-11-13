
/*
 * gpioa_togglepin.c -- Toggle a pin status to GPIOA
 */

#include <stdint.h>

#include <thuasrv32.h>

void gpioa_togglepin(uint32_t pin)
{
	GPIOA->POUT ^= pin;
}
