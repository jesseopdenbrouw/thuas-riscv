/*
 * Read DS18B20 temperature devices
 *
 * The DS18B20s needs Vdd connected to power (3.3 V)
 *
 * See: https://www.analog.com/media/en/technical-documentation/data-sheets/ds18b20.pdf
 *
 * Link with: -u _printf_float
 *
 */

#include <thuasrv32.h>

#ifndef F_CPU
#define F_CPU (50000000UL)
#endif
#ifndef BAUD_RATE
#define BAUD_RATE (115200UL)
#endif

#define MAX_DEVICES (8)

#define READ_ROM (0x33)
#define SKIP_ROM (0xcc)
#define MATCH_ROM (0x55)
#define CONV_TEMP (0x44)
#define READ_SCRATCH (0xbe)

void printdevice(uint8_t r[]) {
	for (int i = 0; i < 8; i++) {
		uart1_printf("%02x", r[i]);
	}
}

int main(void)
{
	uint32_t presence;
	uint8_t data[9];
	uint8_t rom[MAX_DEVICES][8];
	int16_t temp;
	double tempd;
	int i, j, result, cnt;
	uint8_t crc8;

	uart1_init(BAUD_RATE, UART_CTRL_EN);

	uart1_puts("1-Wire DS18B20 Test Program\r\n\n");

	/* Clear all ROM data */
	for (i = 0; i < MAX_DEVICES; i++) {
		for (j = 0; j < 8; j++) {
			rom[i][j] = 0;
		}
	}

	/* Start the reset sequence */
	presence = onewire1_reset();

	/* Halt when no devices are present */
	if (!presence) {
		uart1_puts("No devices found!\r\n");
		while (1);
	}

	cnt = 0;
	/* Scan for 'first' device */
	result = onewire1_findfirst(rom[cnt]);

	while (result) {
		uart1_puts("Device: ");
		printdevice(rom[cnt]);
		if (rom[cnt][0] == 0x28) {
			uart1_puts("  DS18B20 found!");
		} else {
			uart1_puts("  This is not a DS18B20!");
		}
		uart1_puts("\r\n");
		cnt++;
		/* Scan for 'next' device */
		result = onewire1_findnext(rom[cnt]);
	}

	uart1_printf("Number of devices: %d\r\n\n", cnt);

	while (1) {

		/* Reset the bus */
		presence = onewire1_reset();

		if (presence) {

			/* Skip ROM */
			onewire1_transmit_byte(SKIP_ROM);
			/* Convert temperature */
			onewire1_transmit_byte(CONV_TEMP);

			/* Wait for the conversion to complete */
			while (onewire1_receive_byte() == 0);

			/* All the DS18B20 have converted the temperature
             * so now let's read them all out */
			for (i = 0; i < cnt; i++) {

				/* Print device's ROM code */
				printdevice(rom[i]);

				/* If it is a DS18B20... */
				if (rom[i][0] == 0x28) {
					/* Select a device and read the temperature */			
					presence = onewire1_reset();
					onewire1_transmit_byte(MATCH_ROM);
					onewire1_transmit(rom[i], 8);
					onewire1_transmit_byte(READ_SCRATCH);
					onewire1_receive(data, 9);
					crc8 = onewire1_calccrc(data, 9);
					if (crc8 == 0) {

						/* Convert bytes to 16-bit integer */
						temp = (int16_t)((uint16_t) (data[1] <<8)) | ((uint16_t) data[0]);

						/* Temp is in 1/16th degree Celsius */
						tempd = (double)temp / 16.0;
						uart1_printf(": %f\r\n", tempd);
					} else {
						uart1_puts(": CRC8 Failed!\r\n");
					}
				} else {
					uart1_puts(": not a DS18B20\r\n");
				}
			}
			uart1_puts("\r\n");
		}
		delayms(1000);
	}
}

