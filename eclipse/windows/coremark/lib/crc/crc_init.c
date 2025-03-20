
#include <thuasrv32.h>

void crc_init(uint32_t ctrl, uint32_t poly, uint32_t sreg)
{
	CRC->CTRL = ctrl;
	CRC->POLY = poly;
	CRC->SREG = sreg;
}
