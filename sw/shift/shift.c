#include <stdint.h>

int main(void) {

	volatile uint32_t x = 1;
	volatile int32_t y = -31;
	volatile uint64_t z = 0xff00ff00ff00ff00;

	for (int i = 0; i < 32; i++) {
		x = 1 << i;
		y = y >> 1;
	}

	z = z >> 31;
}
