/*
 * Read a DS18B20 temperature device
 *
 * Only one device may be attached!
 * The DS18B20 needs Vdd connected to power (3.3 V)
 *
 * See: https://www.analog.com/media/en/technical-documentation/data-sheets/ds18b20.pdf
 *
 * Link with: -u _printf_float
 *
 */

#include <thuasrv32.h>

#define MAX (2)


#define READ_ROM (0x33)
#define SKIP_ROM (0xcc)
#define CONV_TEMP (0x44)
#define READ_SCRATCH (0xbe)

int main(void)
{
	uint32_t presence;
	uint8_t data[MAX];
	/* Byte 0 = Device Family, byte 7 = CRC8, rest is device ID, LSB first */
	uint8_t rom[8];
	int16_t temp;
	double tempd;
	uint8_t crc = 0;

	uart1_init(BAUD_RATE, UART_CTRL_EN);

	uart1_puts("1-Wire DS18B20 Test Program\r\n\n");

	/* Start the reset sequence */
	presence = onewire1_reset();

	if (presence) {
		/* Read the ROM */
		onewire1_transmit_byte(READ_ROM);
		onewire1_receive(rom, 8);
		/* Print out the data */
		uart1_puts("Device Family: 0x");
		printhex(rom[0], 2);
		/* byte 6 downto 1 has ID */
		uart1_puts("\r\nDevice ID: 0x");
		for (int i = 6; i > 0; i--) {
			printhex(rom[i], 2);
		}
		/* Print out CRC8 */
		uart1_puts("\r\nCRC8: 0x");
		/* Calculate CRC8 over first 7 bytes */
		crc = onewire1_calccrc(rom, 7);
		printhex(crc, 2);
		/* Check if match with calculated CRC8 */
		if (crc == rom[7]) {
			uart1_puts(" --> match!\r\n");
		} else {
			uart1_puts(" --> NO MATCH!\r\n");
		}
	}
	
	while (1) {
		/* Start the reset sequence */
		presence = onewire1_reset();

		if (presence) {

			/* Skip ROM */
			onewire1_transmit_byte(SKIP_ROM);
			/* Convert temperature */
			onewire1_transmit_byte(CONV_TEMP);

			/* Wait for conversion to complete */
			while (onewire1_receive_byte() == 0);

			/* Issue a reset again */
			presence = onewire1_reset();
			if (!presence) {
				break;
			}

			/* Skip ROM */
			onewire1_transmit_byte(SKIP_ROM);
			/* Read scratchpad, only read the first two bytes */
			onewire1_transmit_byte(READ_SCRATCH);
			onewire1_receive(data, MAX);

			/* Convert the bytes to 16-bit integer */
			temp = (int16_t)((uint16_t) (data[1] <<8)) | ((uint16_t) data[0]);

			/* Temp is in 1/16th degree Celsius */
			tempd = (double)temp / 16.0;
			uart1_printf("%f\r\n", tempd);
		} else {
			uart1_puts("No device found\r\n");
		}

		delayms(1000);
	}

}

