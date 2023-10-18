#include <thuasrv32.h>

int main(void)
{
	volatile uint32_t value;

	while (1) {
		value = GPIOA->PIN;

		GPIOA->POUT = value;
	}

	return 0;
}
