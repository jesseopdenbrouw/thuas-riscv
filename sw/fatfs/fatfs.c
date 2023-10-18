#include <stdio.h>

#include "ff.h"
#include "uart.h"

/* Set to 1 for write test on the SD card */
#define WRITE_TEST (1)
#define PRINT_INFO (1)

int main(void)
{
#if PRINT_INFO == 1
	char buffer[40];
#endif
	char line[100];
	const char string[] = "This is a very long sentence with a lot of characters to save in a file\n";
	int count = 0;

	FATFS fs;
	FIL fp;
	FRESULT fr;
	TCHAR label[40] = { 0 };
	DWORD serial = 0;

	uart1_init(BAUD_RATE, UART_CTRL_NONE);

	uart1_puts("\r\nFATFS test program\r\n");

	fr = f_mount(&fs, "", 1);
#if PRINT_INFO == 1
	snprintf(buffer, sizeof buffer, "f_mount: %d\r\n", fr);
	uart1_puts(buffer);
#endif
	if (fr != FR_OK) {
		uart1_puts("Cannot mount SD card!\r\n");
		while (1);
	}

	fr = f_getlabel("", label, &serial);
#if PRINT_INFO == 1
	snprintf(buffer, sizeof buffer, "f_getlabel: %d\r\nlabel: ", fr);
	uart1_puts(buffer);
#endif
	if (fr != FR_OK) {
		uart1_puts("Cannot read label!\r\n");
		while (1);
	}
	uart1_puts(label);
#if PRINT_INFO == 1
	snprintf(buffer, sizeof buffer, "\r\nSerial: %08lx\r\n", serial);
	uart1_puts(buffer);
#endif


	fr = f_open(&fp, "0:read.txt", FA_READ);
#if PRINT_INFO == 1
	snprintf(buffer, sizeof buffer, "f_open: %d\r\n", fr);
	uart1_puts(buffer);
#endif
	if (fr != FR_OK) {
		uart1_puts("Cannot open file read.txt!\r\n");
		while (1);
	} else {

		while (f_gets(line, sizeof line, &fp)) {
#if PRINT_INFO == 1
			snprintf(buffer, sizeof buffer, "%3d: ", ++count);
			uart1_puts(buffer);
#endif
			uart1_puts(line);
			uart1_puts("\r");
		}
	}

	f_close(&fp);

#if WRITE_TEST == 1
	fr = f_open(&fp, "0:write.txt", FA_CREATE_ALWAYS | FA_WRITE);
#if PRINT_INFO == 1
	snprintf(buffer, sizeof buffer, "f_open: %d %p\r\n", fr, &fp);
	uart1_puts(buffer);
#endif
	count = 0;
	uart1_puts("Writing\r\n");
	for (int i = 0; i < 50; i++) {
		count += f_printf(&fp, string);
	}
#if PRINT_INFO == 1
	snprintf(buffer, sizeof buffer, "f_printf: %d\r\n", count);
	uart1_puts(buffer);
#endif
	UINT br;

	fr = f_write(&fp, string, sizeof string-1, &br);
#if PRINT_INFO == 1
	snprintf(buffer, sizeof buffer, "f_write: %d\r\n", fr);
	uart1_puts(buffer);
#endif
	f_close(&fp);
#endif
	uart1_puts("Done\r\n");

	while (1);
}
