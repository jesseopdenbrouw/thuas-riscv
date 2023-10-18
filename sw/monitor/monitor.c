#include <stdio.h>
#include <string.h>
#include <ctype.h>

#include <thuasrv32.h>

/* Frequency of the DE0-CV board */
#ifndef F_CPU
#define F_CPU (50000000UL)
#endif
/* Transmission speed */
#ifndef BAUD_RATE
#define BAUD_RATE (9600UL)
#endif

/* Read a 32-bit address */
uint32_t read_address(char *s) {

	uint32_t val = 0;

	while (isspace((int) *s)) {
		s++;
	}

	if (*s == '\0') {
		return 0;
	}

	while (*s != '\0' && *s != ' ') {
		if (isxdigit((int) *s)) {
			if (isdigit((int) *s)) {
				val = val*16 + *s - '0';
			} else {
				val = val*16 + toupper(*s) - 'A' + 10;
			}
		}
		s++;
	}

	return val;
}

uint32_t read_data_after_address(char *s) {

	uint32_t val = 0;

	while (isspace((int) *s)) {
		s++;
	}
	if (*s == '\0') {
		return 0;
	}
	while (!isspace((int) *s)) {
		s++;
	}
	while (isspace((int) *s)) {
		s++;
	}
	if (*s == '\0') {
		return 0;
	}
	while (*s != '\0') {
		if (isxdigit((int) *s)) {
			if (isdigit((int) *s)) {
				val = val*16 + *s - '0';
			} else {
				val = val*16 + toupper(*s) - 'A' + 10;
			}
		}
		s++;
	}
	return val;
}

int main(void)
{

	char buffer[40] = { 0 };
	int len;
	int little = 1;

	uart1_init(BAUD_RATE, UART_CTRL_NONE);

	uart1_puts("\r\nTHUAS RISC-V FPGA 32-bit processor\r\n");
	uart1_puts("Monitor v0.1\r\n");

	while (1) {

		uart1_puts(">> ");
		uart1_gets(buffer, sizeof buffer);
		len = strlen(buffer);
		if (len == 0) {
			uart1_puts("Enter a command or h for help\r\n");
			continue;
		}

		if (len == 1) {
			if (buffer[0] == 'h') {
				uart1_puts("Commands:\r\n");
				uart1_puts("h -- this help\r\n");
				uart1_puts("l -- set little endian format\r\n");
				uart1_puts("b -- set big endian format\r\n");
				uart1_puts("rw <address> -- read word\r\n");
				uart1_puts("rh <address> -- read half word\r\n");
				uart1_puts("rb <address> -- read byte\r\n");
				uart1_puts("ww <address> <data> -- write word\r\n");
				uart1_puts("wh <address> <data> -- write half word\r\n");
				uart1_puts("wb <address> <data> -- write byte\r\n");
				continue;
			}
			if (buffer[0] == 'b') {
				uart1_puts("Set Big Endian\r\n");
				little = 0;
				continue;
			}
			if (buffer[0] == 'l') {
				uart1_puts("Set Little Endian\r\n");
				little = 1;
				continue;
			}
				
		}

		if (len < 3) {
			uart1_puts("Enter a correct command of h for help\r\n");
			continue;
		}

		if (buffer[0] == 'r') {
			if (buffer[1] == 'w') {
				uint32_t *p = (uint32_t *) read_address(buffer+2);
				if (((uint32_t)p & 3) == 0) {
					uint32_t val = *p;
					if (little) {
						val = ((val & 0xff) << 24) + (((val >> 8) & 0xff) << 16) + (((val >> 16) & 0xff) << 8) + ((val >> 24) & 0xff);
					}
					sprintf(buffer, "%08lx", val);
					uart1_puts(buffer);
				} else {
					uart1_puts("Not on 4-byte boundary");
				}
			} else if (buffer[1] == 'h') {
				uint16_t *p = (uint16_t *) read_address(buffer+2);
				if (((uint32_t)p & 1) == 0) {
					uint16_t val = *p;
					if (little) {
						val = ((val & 0xff) << 8) + ((val >> 8) & 0xff);
					}
					sprintf(buffer, "%04lx", (uint32_t) val);
					uart1_puts(buffer);
				} else {
					uart1_puts("Not on 2-byte boundary");
				}
			} else if (buffer[1] == 'b') {
				uint8_t *p = (uint8_t *) read_address(buffer+2);
				uint8_t val = *p;
				sprintf(buffer, "%02lx", (uint32_t) val);
				uart1_puts(buffer);
			} else {
				uart1_puts("Unknown size");
			}
			uart1_puts("\r\n");
		}

		if (buffer[0] == 'w') {
			if (buffer[1] == 'w') {
				volatile uint32_t *p = (uint32_t *) read_address(buffer+2);
				uint32_t data = read_data_after_address(buffer+2);
				if (((uint32_t)p & 3) == 0) {
					*p = data;
				} else {
					uart1_puts("Not on 4-byte boundary");
				}
			} else if (buffer[1] == 'h') {
				volatile uint16_t *p = (uint16_t *) read_address(buffer+2);
				uint32_t data = read_data_after_address(buffer+2);
				if (((uint32_t)p & 1) == 0) {
					*p = (uint16_t) data;
				} else {
					uart1_puts("Not on 2-byte boundary");
				}
			} else if (buffer[1] == 'b') {
				volatile uint8_t *p = (uint8_t *) read_address(buffer+2);
				uint32_t data = read_data_after_address(buffer+2);
				*p = (uint8_t) data;
			} else {
				uart1_puts("Unknown size");
			}
			uart1_puts("\r\n");
		}
	}

	return 0;
}
