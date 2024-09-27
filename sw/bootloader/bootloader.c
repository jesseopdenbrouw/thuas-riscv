/*
 *
 * bootloader.c -- a simple bootloader for THUAS RISC-V
 *
 * (c)2024, J.E.J. op den Brouw <J.E.J.opdenBrouw@hhs.nl
 *
 */

/* NOTE:
 * DO NOT USE ANY SYSTEM CALLS
 * DO NOT USE FUNCTIONS THAT TRIGGER SYSTEM CALLS
 * (malloc et al, printf et al, times et al)
 */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include <stdint.h>

#include <thuasrv32.h>

#define VERSION "v0.6.3"
#define BUFLEN (41)
#define BOOTWAIT (10)

/* Prototype of the trap handler */
__attribute__ ((interrupt,used))
void trap_handler(void);

/* The bootloader */
int main(int argc, char *argv[], char *envp[]) {

	/* Start address of application */
	void (*app_start)(void) = (void *) 0x00000000;
	/* Buffer for commands */
	char buffer[BUFLEN];
	/* Used in initial delay */
	int count;
	/* Used to test on key hit */
	int keyhit = 0;
	/* Character from UART1 */
	uint8_t c;
	/* Address */
	uint32_t addr = 0;
	/* Do not send response */
	int noresponse = 0;

	/* Initialize UART1 at 115200 bps */
	uart1_init(BAUD_RATE, UART_CTRL_EN);

	/* Send greeting */
	printlogo();

	uart1_puts("\r\nTHUAS RISC-V Bootloader " VERSION "\r\n"
				"Clock frequency: ");
	printdec(csr_read(0xfc1));
	uart1_puts("\r\n");

	/* Wait a short while for a key hit */
	GPIOA->POUT = (1<<BOOTWAIT)-1;
	for (count = 1; count <= BOOTWAIT*1024*1024; count++) {
		/* Modulo power of 2 saves a rem instruction */
		if (count % (1024*1024) == 0) {
			uart1_putc('*');
			GPIOA->POUT >>= 1;
		}
		if (uart1_available()) {
			keyhit = 1;
			break;
		}
	}
	GPIOA->POUT = 0;

	/* If no key was hit within the time frame,
	 * start the application */
	if (!keyhit) {
		uart1_init(0, 0);
		(*app_start)();
	}

	/* Check the entered character */
	/* If it is a ! or $ then enter file upload */
	if ((c = uart1_getc()) == '!' || c == '$') {
		/* If we're not sending a response... */
		if (c == '$') {
			noresponse = 1;
		}
		if (!noresponse) {
			/* Send acknowledge */
			uart1_puts("?\n");
		}
		while (1) {
			/* Read in 'S' */
			GPIOA->POUT ^= 0x01;
			c = uart1_getc();
			if (c == 'S') {
				/* Read in record type */
				c = uart1_getc();
				/* Type 1, 2, 3 is data record */
				if (c == '1' || c == '2' || c == '3') {
					/* Get count, read start address and ignore check byte */
					uint32_t count;
					uint32_t v;
					if (c == '1') {
						count = gethex(2) - 3;
						v = gethex(4);
					} else if (c == '2') {
						count = gethex(2) - 4;
						v = gethex(6);
					} else {
						count = gethex(2) - 5;
						v = gethex(8);
					}
					/* Process bytes */
					for (uint32_t i = 0; i < count; i++) {
						/* Set address, get byte and word data */
						uint32_t *boun = (uint32_t *) (v & ~3);
						uint32_t byte = gethex(2);
						uint32_t word = *boun;

						/* Patch the byte in the word */
						switch (v & 3) {
							case 0: word = (word & ~0xffUL) | byte;
								break;
							case 1: word = (word & ~0xff00UL) | (byte << 8);
								break;
							case 2: word = (word & ~0xff0000UL) | (byte << 16);
								break;
							case 3: word = (word & ~0xff000000UL) | (byte << 24);
								break;
							default:
								break;
						}
						/* Write back the word */
						*boun = word;
						v++;
					}
					/* Read in rest of line */
					while ((c = uart1_getc()) != '\n');
				} else
				/* Type 7, 8, 9 is end record with start address */
				if (c == '7' || c == '8' || c == '9') {
					/* Skip count */
					uint32_t v = gethex(2);
					/* Read in start address */
					if (c == '7') {
						v = gethex(8);
					} else if (c == '8') {
						v = gethex(6);
					} else {
						v = gethex(4);
					}
					/* Read in rest of line */
					while ((c = uart1_getc()) != '\n');
					/* Set start address */
					app_start = (void *) v;
				} else {
					/* Skip other records, eat up line */
					while ((c = uart1_getc()) != '\n');
				}
			} else if (c == 'J') {
				/* Start application after upload */
				if (!noresponse) {
					uart1_puts("?\n");
				}
				uart1_init(0, 0);
				GPIOA->POUT = 0;
				(*app_start)();
				break;
				/* Break to bootloader */
			} else if (c == '#') {
				break;
			}
			if (!noresponse) {
				uart1_puts("?\n");
			}
		}
		/* Signal reception complete */
		GPIOA->POUT = 0xaa;
	}

	/* Set up trap handler */
	set_mtvec(trap_handler, TRAP_DIRECT_MODE);

	/* Start the simple monitor */
	uart1_puts("\r\n");

	while (1) {

		/* Send prompt and read input */
		uart1_puts("> ");
		int len = uart1_gets(buffer, BUFLEN);

		if (strcmp(buffer, "h") == 0) {
			/* Print help */
			uart1_puts("Help:\r\n"
				   " h                - this help\r\n"
				   " r                - run application\r\n"
				   " rw <addr>        - read word from addr\r\n"
				   " ww <addr> <data> - write word data at addr\r\n"
				   " dw <addr>        - dump 16 words\r\n"
				   " n                - dump next 16 words"
				  );
		} else if (strcmp(buffer, "r") == 0) {
			/* Start the application */
			uart1_init(0, 0);
			GPIOA->POUT = 0;
			set_mtvec(0, TRAP_DIRECT_MODE);
			(*app_start)();
		} else if (strncmp(buffer, "rw ", 3) == 0) {
			/* Read word */
			uint32_t v;
			addr = parsehex(buffer+3, NULL);
			if ((addr & 0x3) == 0) {
				printhex(addr,8);
				uart1_puts(": ");
				v = *(uint32_t *) addr;
				printhex(v,8);
			} else {
				uart1_puts("Not on 4-byte boundary!");
			}
		} else if (strncmp(buffer, "ww ", 3) == 0) {
			/* Write word */
			char *s;
			uint32_t v;
			addr = parsehex(buffer+3, &s);
			if ((addr & 0x3) == 0) {
				v = parsehex(s, NULL);
				*(uint32_t *) addr = v;
			} else {
				uart1_puts("Not on 4-byte boundary!");
			}
		} else if ((strncmp(buffer, "dw ", 3) == 0) || (buffer[0] == 'n')) {
			/* Dump 16 words */
			uint32_t v, mask;
			if (buffer[0] != 'n') {
				addr = parsehex(buffer+3, NULL);
			}
			int c;
			if ((addr & 0x3) == 0) {
				for (int i = 0; i < 16; i++) {
					/* Iterate over 16 words */
					printhex(addr,8);
					uart1_puts(": ");
					v = *(uint32_t *) addr;
					printhex(v,8);
					uart1_puts("  ");
					/* Print ASCII code for bytes */
					mask = 0xff000000;
					for (int j = 3; j > -1; j--) {
						c = (v & mask) >> (j*8);
						if (isprint(c)) {
							uart1_putc(c);
						} else {
							uart1_putc('.');
						}
						mask >>= 8;
					}
					addr += 4;
					uart1_puts("\r\n");
				}
				/* Signal suppression of \r\n */
				len = 0;
			} else {
				uart1_puts("Not on 4-byte boundary!");
			}
		} else if (len == 0) {
			/* do nothing */
		} else {
			uart1_puts("??");
		}
		if (len != 0) {
			uart1_puts("\r\n");
		}
	}

	while(1);
}

/* The trap handler handles incoming traps,
 * for now only eceptions. The offending
 * is bypassed by setting the return address
 * one instruction further */
__attribute__ ((interrupt,used))
void trap_handler(void)
{
	uint32_t mepc = csr_read(mepc);
	uint32_t mcause = csr_read(mcause);

	uart1_puts("Trap: mcause = 0x");
	printhex(mcause, 8);
	uart1_puts("\r\n");

	mepc += 4;
	csr_write(mepc, mepc);
}
