/*
 *
 * i2c1tmp102 -- read temperature with I2C1 and TMP102
 *
 * This program reads out the TMP102 digital temperature
 * sensor using the I2C1 peripheral. The target has I2C
 * address 0x48, but this may be changed (on the target)
 * using the ADD0 pin.
 *
 * First, register number 0x00 is send to the TMP102. Then
 * two bytes are read from the TMP102. The TMP102 sends a
 * 12-bit temperature info, left adjusted to 16 bits. Format
 * is 0xhhl0 (hh is high byte, l is low nibble, 0 is 0). The
 * 12-bit temperature is in 1/16th of a degree Celsius. So
 * 0x13b0 indicates 19.6875 degree Celsius. Note that the
 * temperature is in two's complement, so negative values may
 * be read out.
 *
 */

#include <stdio.h>
#include <stdint.h>

#include <thuasrv32.h>

#ifndef F_CPU
#define F_CPU (50000000UL)
#endif
#ifndef BAUD_RATE
#define BAUD_RATE (9600UL)
#endif

#define FAST_MODE (0)
#define TMP102_ADDR (0x48)


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
	char buffer[40];
	uint8_t buf[4];

	uart1_init(BAUD_RATE, UART_CTRL_NONE);

	uart1_puts("I2C1 with TMP102\r\n");

	i2c1_init(TRAN_SPEED | FAST_MODE_BIT);

	while(1) {

		/* Set register to read */
		buf[0] = 0x00;

		/* Write to address, the register number */
		if (i2c1_transmit((TMP102_ADDR << 1) | I2C_WRITE, buf, 1) != 0) {
			uart1_puts("ACK failed!\r\n");
		} else {
			/* All went well, now read two bytes */
			i2c1_receive((TMP102_ADDR << 1) | I2C_READ, buf, 2);

			/* Print out the data */
			snprintf(buffer, sizeof buffer, "HI: 0x%02x, LO: 0x%02x\r\n", buf[0], buf[1]);
			uart1_puts(buffer);
		}

		delayms(1000);
	}
}

