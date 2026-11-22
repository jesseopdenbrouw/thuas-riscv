/*
 * onewire1_receive - receive an array of bytes over the 1-Wire bus
 */

#include <thuasrv32.h>

uint32_t onewire1_receive(uint8_t data[], uint32_t len)
{
	for (uint32_t i = 0; i < len; i++) {
		data[i] = onewire1_receive_byte();
	}

	return 1;
}

