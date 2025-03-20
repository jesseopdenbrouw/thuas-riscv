#include <thuasrv32.h>

void crc_block(uint8_t *block, uint32_t len)
{
	while (len-- > 0) {
		crc_write(*block++);
	}
}
