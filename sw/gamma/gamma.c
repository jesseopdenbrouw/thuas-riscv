/*
 * Since doubles are printed, we need to
 * include the linker flag -u _printf_float
 *
 */

#include <math.h>
#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <time.h>

#include <thuasrv32.h>

/* Frequency of the DE0-CV board */
#ifndef F_CPU
#define F_CPU (50000000UL)
#endif
/* Transmission speed */
#ifndef BAUD_RATE
#define BAUD_RATE (9600UL)
#endif

/* Specify the math function with one parameter only */
#define FUNCTION   tgamma
/* Specify the number of iterations */
#define ITERATIONS 1000

/* To build a string from the function name */
#define STR_VALUE(arg) #arg
#define STR_VALUE_NAME(name) STR_VALUE(name)
#define FUNCTION_NAME STR_VALUE_NAME(FUNCTION)

int main(void)
{
	char buffer[80];
	volatile double x = 0.5;
	volatile double y;

	uart1_init(BAUD_RATE, UART_CTRL_NONE);

	uart1_puts("Calculation of the " FUNCTION_NAME " function\r\n");

	/* Record start time */
	clock_t start = clock();

	/* Do the calculations */
	for (int i = 0; i < ITERATIONS; i++) {
		y = FUNCTION(x);
	}

	/* Record difference */
	start = clock() - start;

	/* Print out the results */
	sprintf(buffer, "x = %.20f, y = %.20f\r\n", x, y);
	uart1_puts(buffer);

	sprintf(buffer, "Number of iterations = %d\r\n", ITERATIONS);
	uart1_puts(buffer);

	sprintf(buffer, "Time: %lu\r\n", start);
	uart1_puts(buffer);


	return 0;
}
