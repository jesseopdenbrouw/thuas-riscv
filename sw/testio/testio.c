#include <stdint.h>

#include <thuasrv32.h>

int main(void) {

	while (1) {
		GPIOA_POUT = GPIOA_PIN;
	}
}
