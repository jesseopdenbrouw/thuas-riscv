/*
 * onewire1_transmit_byte - transmit a byte over the onewire bus
*/

#include <thuasrv32.h>

uint32_t onewire1_transmit_byte(uint32_t data)
{
	ONEWIRE1->DATA = (data & 0xff);

	while ((ONEWIRE1->STAT & ONEWIRE_TC) == 0);

	return ONEWIRE1->STAT;
}
