/*
 * Program to test trigoniometry functions
 * on the processor. Due to large ROM contents
 * we need to select the functions used.
 *
 * Since float/doubles are printed, we need to
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

union {
	double x;
	uint64_t y;
} j;

int main(void)
{
	char buffer[60];

	volatile float a, b, c;
	volatile float w = 0.57f;

	volatile double y = 0.57;
	volatile double k, l, m;

	j.x = y;

	uart1_init(BAUD_RATE, UART_CTRL_NONE);

	uart1_puts("float and double calculations\r\n");

	sprintf(buffer, "'0.57' = %.20f = %08lx%08lx\r\n", y, (uint32_t) (j.y>>32), (uint32_t) (j.y & 0xffffffff));
	uart1_puts(buffer);

	/* Record start time */
	clock_t start = clock();

	/* Do the calculations */
	a = sinf(w);
	b = asinf(w);
	c = logf(w);

	k = sin(y);
	l = asin(y);
	m = tan(y);

	/* Record difference */
	start = clock() - start;

	/* Print out the results */
	sprintf(buffer, "sinf(%.10f) = %.10f\r\n", w, a);
	uart1_puts(buffer);

	sprintf(buffer, "asinf(%.10f) = %.10f\r\n", w, b);
	uart1_puts(buffer);

	sprintf(buffer, "logf(%.10f) = %.10f\r\n", w, c);
	uart1_puts(buffer);


	sprintf(buffer, "sin(%.20f) = %.20f\r\n", y, k);
	uart1_puts(buffer);

	sprintf(buffer, "asin(%.20f) = %.20f\r\n", y, l);
	uart1_puts(buffer);

	sprintf(buffer, "tan(%.20f) = %.20f\r\n", y, m);
	uart1_puts(buffer);


	sprintf(buffer, "Time: %lu\r\n", start);
	uart1_puts(buffer);


	return 0;
}
