/*
 * i2c1ssd1315.c -- Program to drive an SSD1315 display
 *
 * This program drives a display using an SSD1315
 * display driver as found on the Arduino Sensor Kit.
 * See https://store.arduino.cc/products/arduino-sensor-kit-base
 */

#include <stdint.h>

#include <thuasrv32.h>
#include "ssd1315.h"

#ifndef F_CPU
#define F_CPU (50000000UL)
#endif
#ifndef BAUD_RATE
#define BAUD_RATE (115200UL)
#endif

#define FAST_MODE (1)

#if FAST_MODE == 1
/* Fast mode (Fm), 400 kHz */
#define TRAN_SPEED I2C_PRESCALER_FM(csr_read(0xfc1))
#define FAST_MODE_BIT I2C_FAST_MODE
#else
/* Standard mode (Sm), 100 kHz */
#define TRAN_SPEED I2C_PRESCALER_SM(csr_read(0xfc1))
#define FAST_MODE_BIT I2C_STANDARD_MODE
#endif

int main(void) {

	ssd1315_status_t ret;
	uint8_t buf[10] = {0};

	i2c1_init(TRAN_SPEED | FAST_MODE_BIT);

	ret = ssd1315_init();

	ret = ssd1315_setpos(0,0);

	ret = ssd1315_fillscreen(0x00);

	ret = ssd1315_setpos(0,0);

	buf[0] = 0x40;  // data
	buf[1] = 0x00;  // ........
	buf[2] = 0x01;  // .......*
	buf[3] = 0x03;  // ......**
	buf[4] = 0x07;  // .....***
	buf[5] = 0x0f;  // ....****
	buf[6] = 0x1f;  // ...*****
	buf[7] = 0x3f;  // ..******
	buf[8] = 0x7f;  // .*******
	buf[9] = 0xff;  // ********

	i2c1_transmit(SSD1315_ADDR, buf, 10);

	ret = ssd1315_setpos(16,0);
	ret = ssd1315_puts("Hallo THUAS RV32!");

	while (1) {
		for (uint8_t i = 32; i<128; i++) {
			ret = ssd1315_setpos(0,2);
			ret = ssd1315_putchar(i);
			delayms(1000);
		}
	}
}

