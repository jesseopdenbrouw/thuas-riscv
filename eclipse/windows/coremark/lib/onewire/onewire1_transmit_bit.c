/*
 * onewire1_transmit_bit - transmit one bit (lsb) over the 1-Wire bus
 *
 */

#include <thuasrv32.h>

uint32_t onewire1_transmit_bit(uint32_t bit)
{
	/* Set bit mode */
	ONEWIRE1->CTRL |= ONEWIRE_ONEBIT;

	/* Transmit bit, bit in lsb */
	ONEWIRE1->DATA = bit;

	/* Wait for it... */
	while ((ONEWIRE1->STAT & ONEWIRE_TC) == 0);

	/* Set byte mode */
	ONEWIRE1->CTRL &= ~ONEWIRE_ONEBIT;

	return 1;
}
	
