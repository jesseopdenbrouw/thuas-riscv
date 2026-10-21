/*
 * onewire_reset - send a reset pulse and return presence
 */

#include <thuasrv32.h>

uint32_t onewire1_reset(void)
{
	/* Start the reset sequence */
	ONEWIRE1->CTRL |= ONEWIRE_RESET;

	/* Wait while busy */
	while (!(ONEWIRE1->STAT & ONEWIRE_PC));

	/* Filter presence bit */
	return ONEWIRE1->STAT & ONEWIRE_PRESENCE ? 1 : 0;
}

