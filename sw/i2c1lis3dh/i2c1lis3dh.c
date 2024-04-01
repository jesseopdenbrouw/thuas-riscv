/*
 * i2c1lis3dh.c -- Program to use a LIS3DH accelerometer
 *
 * This program reads acceleration information from a LIS3DH
 * accelerometer as found on the Arduino Sensor Kit.
 * See https://store.arduino.cc/products/arduino-sensor-kit-base
 * See https://www.st.com/resource/en/datasheet/lis3dh.pdf
 */

#include <math.h>
#include <stdint.h>

#include <thuasrv32.h>

#ifndef F_CPU
#define F_CPU (50000000UL)
#endif
#ifndef BAUD_RATE
#define BAUD_RATE (9600UL)
#endif

#define FAST_MODE (1)
#define LIS3DH_ADDR (0x19)


#if FAST_MODE == 1
/* Fast mode (Fm), 400 kHz */
#define TRAN_SPEED I2C_PRESCALER_FM(csr_read(0xfc1))
#define FAST_MODE_BIT I2C_FAST_MODE
#else
/* Standard mode (Sm), 100 kHz */
#define TRAN_SPEED I2C_PRESCALER_SM(csr_read(0xfc1))
#define FAST_MODE_BIT I2C_STANDARD_MODE
#endif

int main(void)
{
	/* Buffer for data, begin with all axis on, 10 Hz update rate */
	uint8_t buf[10] = { 0x20, 0x27, 0x00 };
	int16_t x, y, z;
	uint32_t ret;
	char buffer[128];

	/* Initialize UART1 */
	uart1_init(BAUD_RATE, UART_CTRL_EN);

	/* Initialize I2C1 */
	i2c1_init(TRAN_SPEED | FAST_MODE_BIT);

	/* Welcome */
	uart1_puts("\r\nLIS3DH Accelerometer Test Program\r\n\n");
 
	/* Set up LIS3DH: all axes on, 10 Hz update rate */
	ret = i2c1_transmit((LIS3DH_ADDR << 1) | I2C_WRITE, buf, 2);
	if (ret) {
		uart1_puts("LIS3DH not found!\r\n");
		while (1);
	}

	while (1) {
		/* Set register pointer + auto increment */
		buf[0] = 0x28 | 0x80;

		/* Transmit register pointer */
		ret = i2c1_transmit((LIS3DH_ADDR << 1) | I2C_WRITE, buf, 1);

		if (!ret) {
			/* Get the raw accelerometer data */
			ret = i2c1_receive((LIS3DH_ADDR << 1) | I2C_READ, buf, 6);
			if (!ret) {
				/* Calculate Ax, Ay, Az in milli g */
				x = (int16_t) buf[0] | (int16_t) buf[1] << 8;
				x = x / 16;
				y = (int16_t) buf[2] | (int16_t) buf[3] << 8;
				y = y / 16;
				z = (int16_t) buf[4] | (int16_t) buf[5] << 8;
				z = z / 16;

				/* Calculate roll and pitch in degrees */
				int roll = atan2f(y,sqrtf(x*x + z*z)) * 180.0f/(float) M_PI + 0.5f;
				int pitch = atan2f(-x,sqrtf(y*y + z*z)) * 180.0f/(float) M_PI + 0.5f;

				snprintf(buffer, sizeof buffer, "x: %5d, y: %5d, z: %5d, pitch: %3d, roll: %3d\r\n", x, y, z, pitch, roll);
				uart1_puts(buffer);
			} else {
				uart1_puts("Failed to receive info!\r\n");
			}
		} else {
			uart1_puts("Failed to set register!\r\n");
		}

		delayms(100);
	}

}

