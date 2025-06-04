/*
 * handlers_direct.c -- exception and interrupt handlers for direct exceptions
 *
 * Note: these handlers are called by the universal handler
 *       since we are using direct traps, hence they are callable
 *
 * (c) 2025, Jesse E.J. op den Brouw <J.E.J.opdenBrouw@hhs.nl>
 *
 */

#include <thuasrv32.h>

/* Leave this at 1 M */
#ifndef CLOCK_FREQUENCY
#define CLOCK_FREQUENCY (1000000ULL)
#endif
#ifndef INTERRUPT_FREQUENCY
#define INTERRUPT_FREQUENCY (10ULL)
#endif

/* Set TIMECMP delta to some reasonable value */
static uint64_t external_timer_delta = (CLOCK_FREQUENCY/INTERRUPT_FREQUENCY);

/* Debugger stub, currenly prints the contents of
 * mepc CSR and instruction.
 * The debugger function must NOT call any system
 * calls or trigger execptions. */
void debugger(trap_frame_t *tf)
{
	static const char hex[] = "0123456789abcdef";

	/* Buffer for printing */
	char buf[12];

	register uint32_t val = tf->mepc;

	/* You cannot use printf here as it uses ECALL */
	uart1_puts("\r\nEBREAK! mepc = ");

	for (int i = 7; i >= 0; i--) {
		buf[i] = hex[val & 0xf];
		val >>= 4;
	}
	buf[8] = '\0';
	uart1_puts(buf);

	uart1_puts(" insn = ");
	val = tf->instr;
	for (int i = 7; i >= 0; i--) {
		buf[i] = hex[val & 0xf];
		val >>= 4;
	}
	uart1_puts(buf);
	uart1_puts("\r\n");
}

/* TIMER1 compare match T interrupt processing */
void timer1_handler(void)
{
	/* Remove CMPT interrupt flag */
	TIMER1->STAT &= ~(1<<4);
	/* Flip output bit 0 (led) */
	GPIOA->POUT ^= 0x1;
}

/* The default handler, which holds the processor */
void default_handler(void)
{
	/* Set output bit 9 and hold */
	GPIOA->POUT |= (1 << 9);
	while(1);
}

/* The RISC-V external timer can be found in memory
 * mapped addresses in the I/O. Asserts an interrupt
 * when TIMECMPH:TIMECMP >= TIMEH:TIME. By writing
 * a greater number in TIMECMPH:TIMECMP, the
 * interrupt is negated. */
void external_timer_handler(void)
{
	register uint32_t time;
	register uint32_t timeh;

	/* Fetch current time */
	do {
		timeh = MTIMEH;
		time  = MTIME;
	} while (timeh != MTIMEH);

	/* Fetch current time */
	register uint64_t cur_time = ((uint64_t)timeh << 32) | (uint64_t)time;

	/* Add delta */
	cur_time += external_timer_delta;
	/* Set TIMECMP to maximum */
	MTIMECMPH = -1;
	MTIMECMP = -1;
	/* Store new TIMECMP */
	MTIMECMP = (uint32_t)(cur_time & 0xffffffff);
	MTIMECMPH = (uint32_t)(cur_time>>32);
	/* Flip output bit 1 (led) */
	GPIOA->POUT ^= 0x2;
}

/* UART1 receive and/or transmit handler */
void uart1_handler(void)
{
	/* Test to see if character is received or transmitted.
	 * Test to see if there are any errors. */

	if (UART1->STAT & UART_STAT_RC) {
		/* Flip output bit 3 */
		GPIOA->POUT ^= 0x8;
		/* Clear all receive flags, discard data */
		(void) UART1->DATA;
	}

	/* Don't use UART1->STAT = 0x00 otherwise the
	 * transmit complete flag can be written 0 just
	 * after transmit is really completed and the
	 * uart1_putc() function will hang */
}

/* TIMER2 compare match T/A/B/C interrupt processing */
void timer2_handler(void)
{
	/* Remove CMPT/A/B/C interrupt flags */
	TIMER2->STAT &= ~(0xf<<4);
	/* Flip output bit 2 (led) */
	GPIOA->POUT ^= 0x4;
}

/* SPI1 transmission complete interrupt handler */
void spi1_handler(void)
{
	/* Remove TC interrupt flag */
	SPI1->STAT &= ~SPI_TC;
	/* Flip output bit 4 (led) */
	GPIOA->POUT ^= 0x10;
}

/* I2C1 transmit complete interrupt handler */
void i2c1_handler(void)
{
	/* Remove TC interrupt flag */
	I2C1->STAT &= ~I2C_TC;
	/* Flip output bit 5 (led) */
	GPIOA->POUT ^= 0x20;
}

/* I2C2 transmit complete interrupt handler */
void i2c2_handler(void)
{
	/* Remove TC interrupt flag */
	I2C2->STAT &= ~I2C_TC;
	/* Flip output bit 7 */
	GPIOA->POUT ^= 0x80;
}

/* External pin input interrupt handler */

void external_input_handler(void)
{
	/* Remove pending interrupt bit */
	GPIOA->EXTS = 0x00;
	/* Toggle output bit 6 (led) */
	GPIOA->POUT ^= 0x40;
}

/* External Machine Software Interrupt (MSI) */

void external_msi_handler(void)
{
	/* Remove pending interrupt bit */
	MSI->TRIG = 0x00;
	/* Toggle output bit 8 (led) */
	GPIOA->POUT ^= 0x100;
}
