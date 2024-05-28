/*
 * uart1_interrupt.c
 *
 */

#include <stdio.h>

#include <thuasrv32.h>

/* Code in mcause */
#define MCAUSE_IS_UART1 ((1<<31)+23)

/* Global pointer to send string */
volatile char *transmit_string = NULL;
/* Global pointer to receive string */
volatile char *receive_string = NULL;
/* */
volatile int current_length, string_length;

/* UART1 puts with interrupt */
int uart1_putsIT(char *str);
/* Get a string using interrupts */
int uart1_getsIT(char *str, int len);


/* Prototype of handler */
__attribute__ ((interrupt, used))
void trap_handler(void);

int main(void)
{
	/* Buffer for snprintf */
    char buffer[6];

    /* Initialize UART1 */
    uart1_init(115200, UART_CTRL_EN);

    /* Register trap handler */
	set_mtvec(trap_handler, TRAP_DIRECT_MODE);

	/* Enable IRQs */
	enable_irq();

	while (uart1_putsIT("\r\nTHUAS RV32 Serial Port Interrupt Test Program\r\n\n") == 1);

	while (1) {

		/* Print a string */
		while (uart1_getsIT(buffer, sizeof buffer) == 1) {
			/* Do something useful here */
		}

		while (uart1_putsIT(buffer) == 1) {
			/* Do something useful here */
		}
	}

	return 0;
}

/* Transmit a string using interrupts */
int uart1_putsIT(char *str)
{
	/* Keep track if we are still sending */
	static int still_sending = 0;

	/* Duhh... */
	if (str == NULL || str[0] == '\0') {
		/* Not sending a string */
		transmit_string = NULL;
		still_sending = 0;
		/* Disable transmit interrupt */
		UART1->CTRL &= ~UART_CTRL_TCIE;
		return 0;
	}

	if (transmit_string != NULL) {
		/* Still transmitting */
		return 1;
	} else {
		/* Transmit buffer empty */
		if (still_sending == 1) {
			still_sending = 0;
			return 0;
		} else {
			transmit_string = str+1;
			still_sending = 1;
			/* Send first character */
			UART1->DATA = *str;
			/* Enable transmission interrupt */
			UART1->CTRL |= UART_CTRL_TCIE;
			return 1;
		}
	}
}

/* Get a string using interrupts */
int uart1_getsIT(char *str, int len) {

	static int still_receiving = 0;

	if (str == NULL || len < 1) {
		receive_string = NULL;
		string_length = 0;
		still_receiving = 0;
		UART1->CTRL &= ~UART_CTRL_RCIE;
		return 0;
	}

	if (len < 2) {
		*str = '\0';
		receive_string = NULL;
		string_length = 0;
		still_receiving = 0;
		UART1->CTRL &= ~UART_CTRL_RCIE;
		return 0;
	}

	if (receive_string != NULL) {
		return 1;
	} else {
		if (still_receiving == 1) {
			still_receiving = 0;
			return 0;
		} else {
			receive_string = str;
			string_length = len;
			still_receiving = 1;
			UART1->CTRL |= UART_CTRL_RCIE;
			return 1;
		}
	}
	return 0;
}

__attribute__ ((interrupt, used))
void trap_handler(void)
{
	/* Get mcause */
	uint32_t mcause = csr_read(mcause);


	/* Test for UART1 interrupt */
	if (mcause == MCAUSE_IS_UART1) {
		//gpioa_togglepin(GPIO_PIN_ALL);

		/* Transmit interrupt */
		if (UART1->STAT & UART_STAT_TC) {

			gpioa_togglepin(GPIO_PIN_1);

			if (transmit_string == NULL) {
				/* Should not happen */
				/* Disable TC interrupt and clear flag */
				/* Otherwise interrupts will repeatedly occur! */
				UART1->CTRL &= ~UART_CTRL_TCIE;
				UART1->STAT &= ~UART_STAT_TC;
			} else {
				if (*transmit_string != '\0') {
					/* Send character */
					UART1->DATA = *transmit_string;
					transmit_string++;
				} else {
					/* End of string reached */
					transmit_string = NULL;
					/* Disable TC interrupt and clear flag */
					/* Otherwise interrupts will repeatedly occur! */
					UART1->CTRL &= ~UART_CTRL_TCIE;
					UART1->STAT &= ~UART_STAT_TC;
				}
			}
		}

		/* Receive interrupt */
		if (UART1->STAT & UART_STAT_RC) {

			char ch = UART1->DATA;

			gpioa_togglepin(GPIO_PIN_0);

			if (receive_string == NULL) {
				/* Disable interrupt */
				UART1->CTRL &= ~UART_CTRL_RCIE;
			} else {
				if ((current_length == string_length-2) || (ch == '\r' || ch == '\n')) {
					if (ch == '\r') {
						ch = '\n';
					}
					*receive_string = ch;
					receive_string++;
					*receive_string = '\0';
					receive_string = NULL;
					UART1->CTRL &= ~UART_CTRL_RCIE;
					string_length = 0;
					current_length = 0;
					return;
				}
				*receive_string = ch;
				current_length++;
				receive_string++;
			}

		}

	} /* mcause */

}
