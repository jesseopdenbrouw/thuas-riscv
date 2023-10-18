#include <stdint.h>

#include <thuasrv32.h>

int main(void) {

	volatile uint32_t value;

	while (1) {

		/* Read in the 10 switches */
		value = GPIOA_PIN;

		/* Add switches 0-4 to switches 5-9 */
		value = (value & 0x0000001f) + ((value >> 5) & 0x0000001f);

		/* Output result to the leds */
		GPIOA_POUT = value;
	}
}
