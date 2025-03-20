
#include <thuasrv32.h>

uint32_t crc_get(void)
{
	return CRC->SREG;
}
