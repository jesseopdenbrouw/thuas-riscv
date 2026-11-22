/*
 * onewire1_transmit - transmit bytes over the 1-Wire bus
 *
 */

#include <thuasrv32.h>

uint32_t onewire1_transmit(uint8_t data[], uint32_t len)
{
	for (uint32_t i = 0; i < len; i++) {
		onewire1_transmit_byte(data[i]);
	}
	return 1;
}

