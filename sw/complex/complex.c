
/* check that exp(i * pi) == -1 */
#include <math.h>        /* for atan */
#include <stdio.h>
#include <complex.h>

#include <thuasrv32.h>

int main(void)
{
	double pi = 4 * atan(1.0);
	double complex z = cexp(I * pi);

	uart1_init(BAUD_RATE, UART_CTRL_EN);

	uart1_printf("%f + %f * i\r\n", creal(z), cimag(z));
}

