#include <stdint.h>

#include <thuasrv32.h>

int main(void) {

	volatile uint32_t counter;

	while (1) {
		/* Set all outputs high */
		GPIOA_POUT = 0xffffffff;
		/* Wait a bit */
		for (counter = 0; counter < 5000000; counter ++);
		/* Invert all outputs */
		GPIOA_POUT = ~GPIOA_POUT;
		/* Wait a bit */
		for (counter = 0; counter < 5000000; counter ++);
	}
}
