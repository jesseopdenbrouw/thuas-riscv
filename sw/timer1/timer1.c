/*
 * timer1.c - test TIMER1
 *
 */

#include <thuasrv32.h>

/* Frequency of the DE0-CV board */
#ifndef F_CPU
#define F_CPU (50000000UL)
#endif
/* Transmission speed */
#ifndef BAUD_RATE
#define BAUD_RATE (9600UL)
#endif

/* Interrupt frequency TIMER1 */
#define TIMER1_FREQ (1UL)

int main(void)
{
	/* Get clock frequency */
	uint32_t speed = csr_read(0xfc1);
	speed = (speed == 0) ? F_CPU : speed;

	/* Redirect all traps to handler */
	set_mtvec(trap_handler, TRAP_DIRECT_MODE);

	/* Set CMPT register */
	timer1_setcompare(speed/TIMER1_FREQ-1UL);
	/* Enable interrupt */
	timer1_enable_interrupt();
	/* Enable timer */
	timer1_enable();

	/* Enable global IRQ */
	enable_irq();

	//timer1_disable();

	while(1);
}

/* Trap handler, just invert POUT2
 * and clear interrupt flag */
__attribute__((interrupt, used))
void trap_handler(void)
{
	GPIOA->POUT ^= (1 << 15) | (1 << 2);
	timer1_clear_interrupt();
}
