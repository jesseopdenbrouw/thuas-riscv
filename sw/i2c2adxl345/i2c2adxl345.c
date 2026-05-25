/*
 * i2c2adxl345.c -- Program to use a LIS3DH accelerometer
 *
 * This program reads acceleration information from a ADXL345
 * accelerometer as found on the DE10-Lite board
 * See https://www.terasic.com.tw/cgi-bin/page/archive.pl?Language=English&CategoryNo=234&No=1021
 */

#include <math.h>
#include <stdint.h>

#include <thuasrv32.h>

#ifndef F_CPU
#define F_CPU (50000000UL)
#endif
#ifndef BAUD_RATE
#define BAUD_RATE (115200UL)
#endif

#define FAST_MODE (1)
#define ADXL345_ADDR (0x53)


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
	/* Buffer for data */
	uint8_t buf[10] = { 0x00 };
	int16_t x, y, z;
	uint32_t ret;
	char buffer[128];

	/* Initialize UART1 */
	uart1_init(BAUD_RATE, UART_CTRL_EN);

	/* Initialize I2C2 */
	i2c2_init(TRAN_SPEED | FAST_MODE_BIT);

	/* Welcome */
	uart1_puts("\r\nADXL345 Accelerometer Test Program\r\n\n");
 
	/* Set up ADXL345: 13 bits, justify left */
	buf[0] = 0x31;
	buf[1] = 0x0c;
	ret = i2c2_transmit((ADXL345_ADDR << 1) | I2C_WRITE, buf, 2);
	if (ret) {
		uart1_puts("ADXL345 not found!\r\n");
		while (1);
	}

	/* Set up ADXL345: enable */
	buf[0] = 0x2d;
	buf[1] = 0x08;
	ret = i2c2_transmit((ADXL345_ADDR << 1) | I2C_WRITE, buf, 2);
	if (ret) {
		uart1_puts("ADXL345 not found!\r\n");
		while (1);
	}
	while (1) {
		/* Set register pointer */
		buf[0] = 0x32;

		/* Transmit register pointer */
		ret = i2c2_transmit((ADXL345_ADDR << 1) | I2C_WRITE, buf, 1);

		if (!ret) {
			/* Get the raw accelerometer data */
			ret = i2c2_receive((ADXL345_ADDR << 1) | I2C_READ, buf, 6);
			if (!ret) {
				/* Calculate Ax, Ay, Az in milli g */
				x = (uint16_t) buf[0] | ((uint16_t) buf[1] << 8);
				x = x / 16;
				y = (uint16_t) buf[2] | ((uint16_t) buf[3] << 8);
				y = y / 16;
				z = (uint16_t) buf[4] | ((uint16_t) buf[5] << 8);
				z = z / 16;

				/* Calculate roll and pitch in degrees */
				int roll = atan2f(y,sqrtf(x*x + z*z)) * 180.0f/(float) M_PI;
				int pitch = atan2f(-x,sqrtf(y*y + z*z)) * 180.0f/(float) M_PI;

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

