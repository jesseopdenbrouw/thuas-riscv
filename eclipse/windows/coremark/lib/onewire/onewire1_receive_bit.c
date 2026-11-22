/*
 * onewire1_receive_bit - receive one bit over the 1-Wire bus
 *
 */

#include <thuasrv32.h>

uint32_t onewire1_receive_bit(void)
{
	/* Only one bit, lsb */
	ONEWIRE1->CTRL |= ONEWIRE_ONEBIT;

	/* Start reading, use dummy byte */
	ONEWIRE1->READ = 0x00;

	/* Wait for it... */
	while ((ONEWIRE1->STAT & ONEWIRE_RC) == 0);

	/* Restore byte mode */
	ONEWIRE1->CTRL &= ~ONEWIRE_ONEBIT;

	/* Only lsb, but data is shifted from the high end,
     * so we have to shift it to bit 0 */
	return ONEWIRE1->DATA >> 7;
}
