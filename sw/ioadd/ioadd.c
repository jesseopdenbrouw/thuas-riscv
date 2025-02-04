/*
 * ioadd.c - read on the switches as binary numbers, add them and display on the leds
 *
 */

#include <thuasrv32.h>

/* Frequency of the DE0-CV board */
#ifndef F_CPU
#define F_CPU (50000000UL)
#endif
/* Transmission speed */
#ifndef BAUD_RATE
#define BAUD_RATE (115200UL)
#endif

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
