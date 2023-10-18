#include <stdint.h>

int main(void) {

	volatile uint32_t x = 1;
	volatile int32_t y = -31;
	volatile uint64_t z = 0xff00ff00ff00ff00;

	x = x << 4;
	y = y >> 4;

	z = z >> 31;
}
