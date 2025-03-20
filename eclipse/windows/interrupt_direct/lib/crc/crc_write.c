
#include <thuasrv32.h>

void crc_write(uint8_t data)
{
	CRC->DATA = data;

	while ((CRC->STAT & CRC_TC) == 0);
}
