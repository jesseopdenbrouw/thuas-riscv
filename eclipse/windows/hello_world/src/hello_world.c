/*
 * hello_world.c
 *
 *  Created on: 6 Sept 2024
 *      Author: jesse
 */

#include <thuasrv32.h>

int main(void)
{
	int count = 0;

	uart1_init(115200, UART_CTRL_EN);

	while (1) {
		uart1_puts("Hello from Eclipse! (");
		printdec(count++);
		uart1_puts(")\r\n");
		gpioa_writepin(GPIO_PIN_0, GPIO_PIN_SET);
		delayms(250);
		gpioa_writepin(GPIO_PIN_0, GPIO_PIN_RESET);
		delayms(250);
	}
}
