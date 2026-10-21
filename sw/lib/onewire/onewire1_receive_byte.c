/*
 * onewire1_receive_byte - receivea byte over the onewire bus
*/

#include <thuasrv32.h>

uint32_t onewire1_receive_byte(void)
{
	/* Dummy write to register to start a reception */
	ONEWIRE1->READ = 0x00;

	/* Wait for reception complete */
	while ((ONEWIRE1->STAT & ONEWIRE_RC) == 0);

	/* Return data */
	return ONEWIRE1->DATA;
}
