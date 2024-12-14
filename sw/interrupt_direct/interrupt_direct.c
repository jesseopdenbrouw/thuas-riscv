/*
 * interrupt_direct.c -- handle interrupts in direct mode
 *
 */


#include <stdint.h>
#include <malloc.h>
#include <sys/time.h>
#include <string.h>
#include <unistd.h>
#include <stdio.h>

#include <thuasrv32.h>

/* Set to 1 to use printf(), uses system calls.
 * Set to 0 to use sprintf()/uart1_puts(), uses
 * at most sbrk system call */
#define USE_PRINTF (0)

/* Should be loaded by the Makefile */
#ifndef F_CPU
#define F_CPU (50000000UL)
#endif
#ifndef BAUD_RATE
#define BAUD_RATE (115200UL)
#endif

int main(int argc, char *argv[], char *envp[])
{
	struct timeval tv;
	uint32_t hour, min, sec;
	uint32_t ebreak_counter = 0;
	uint32_t speed;
	uint32_t has_ocd = csr_read(0xfc0) & CSR_MXHW_OCD;

#if USEPRINTF != 1
	char buffer[40] = {0};
#endif

	/* Get system frequency */
	speed = csr_read(0xfc1);
	speed = (speed == 0) ? F_CPU : speed;

	/* Set the trap handler vector */
	set_mtvec(trap_handler_direct, TRAP_DIRECT_MODE);

	/* Initialize the USART*/
	uart1_init(BAUD_RATE, UART_CTRL_RCIE | UART_CTRL_EN);

	/* Activate TIMER1 with a cycle of 1 Hz */
	TIMER1->CMPT = speed/2-1;
	/* Bit 0 = enable, bit 4 is interrupt enable */
	TIMER1->CTRL = (1<<4)|(1<<0);

	/* Activate TIMER2 compare T interrupt with a cycle of 0.5 Hz */
	TIMER2->PRSC = speed/10000UL-1;
	TIMER2->CMPT = 9999UL;
	TIMER2->CTRL = (1<<4)|(1<<0);

	/* Activate SPI1 transmission complete interrupt */
	/* with /256 prescaler, 8-bit data, mode 0 */
	SPI1->CTRL = SPI_PRESCALER7 | SPI_TCIE | SPI_SIZE8 | SPI_MODE0;

	/* Activate I2C1 transmit/receive complete interrupt */
	/* Standard mode, 100 kHz */
	I2C1->CTRL = I2C_PRESCALER_SM(speed) | I2C_TCIE | I2C_STANDARD_MODE;

	/* Activate I2C2 transmit/receive complete interrupt */
	/* Fast mode, 400 kHz */
	I2C2->CTRL = I2C_PRESCALER_FM(speed) | I2C_TCIE | I2C_FAST_MODE;

	/* External input pin interrupt, pin 15, rising edge */	
	GPIOA->EXTC = (15 << 3) | (1 << 1);

	/* Enable RISC-V system timer IRQ */
	enable_external_timer_irq();

	/* Enable RISC-V Machine Software IRQ */
	enable_external_software_irq();

	/* Enable interrupts */
	enable_irq();

#if USEPRINTF == 1
	printf("\r\n");
	while(argc-- > 0) {
		printf("%s\r\n", *argv++);
	}
	printf("\r\n\nDisplaying the time passed since reset\r\n\n");
#else
	uart1_puts("\r\n");
	while(argc-- > 0) {
		uart1_puts(*argv++);
		uart1_puts("\r\n");
	}
	uart1_puts("\r\n\nDisplaying the time passed since reset\r\n\n");
#endif
	if (has_ocd) {
		uart1_puts("On-chip debugger found, skipping EBREAK instruction\r\n\r\n");
	}

	while (1) {
		/* Read in the time of the day */
		int status = gettimeofday(&tv, NULL);

		/* Produce hours, minutes and seconds */
		hour = tv.tv_sec / 3600UL;
		min = (tv.tv_sec / 60UL) % 60UL;
		sec = tv.tv_sec % 60UL;

		if (status == 0) {
#if USEPRINTF == 1
			printf("%05ld:%06ld", (int32_t) tv.tv_sec, tv.tv_usec);
			printf("   %02ld:%02ld:%02ld\r", hour, min, sec);
#else
			sprintf(buffer, "%05ld:%06ld   %02ld:%02ld:%02ld\r",
				(int32_t) tv.tv_sec, tv.tv_usec, hour, min, sec);
			uart1_puts(buffer);
#endif
		}

		/* Once in every +/- 10 seconds, produce an EBREAK call */
		ebreak_counter++;
		if (ebreak_counter == BAUD_RATE/24UL) {
			ebreak_counter = 0;
			if (!has_ocd) {
				ebreak();
			}
			/* Start SPI1 transmission */
			SPI1->DATA = 0xff;
			/* Start I2C1 transmission, send START and STOP */
			/* Send address 0x48 (TMP102 device) */
			I2C1->CTRL |= I2C_START | I2C_STOP;
			I2C1->DATA = (0x48 << 1);
			/* Start I2C2 transmission, send START and STOP */
			/* Send address 0x48 (TMP102 device) */
			I2C2->CTRL |= I2C_START | I2C_STOP;
			I2C2->DATA = (0x48 << 1);
			/* Trigger Machine Software IRQ (MSI) */
			MSI->TRIG = 0x01;
		}
	}

	return 0;
}
