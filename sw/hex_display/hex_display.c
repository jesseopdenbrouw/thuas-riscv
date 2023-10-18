#include <stdint.h>

#include <thuasrv32.h>

int main(void) {

	const uint8_t hex[] = { 0x40, 0x79, 0x24, 0x30,
	                        0x19, 0x12, 0x02, 0x78,
	                        0x00, 0x10, 0x08, 0x03,
	                        0x46, 0x21, 0x06, 0x0e };
	uint32_t value;
	uint8_t out0, out1;

	while (1) {
		value = GPIOA->PIN;
		value &= 0xff;

		out1 = hex[(value & 0xf0) >> 4];
		out0 = hex[(value & 0x0f)];

		GPIOA->POUT = (out1 << 24) | (out0 << 16);
	}

	return 0;
}
