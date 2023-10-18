/*
 * test_double.c -- program to generate contents
 *                  of double variabels in hexadecimal
 *
 * compile with: gcc -o test_double test_double.c -lm
 *
 * Note: RISC-V must be Little Endian
 *
 */

#include <stdio.h>
#include <math.h>

union {
	double x;
	unsigned long long int y;
} t, k;

double x;

int main(void) {


	k.x = 0.57;

	printf("0.57 = %.20f = %20llx\n", k.x, k.y);

	t.x = sin(k.x);
	printf("sin(%.20f) = %.20f = %020llx\n", k.x, t.x, t.y);

	t.x = asin(k.x);
	printf("asin(%.20f) = %.20f = %020llx\n", k.x, t.x, t.y);

	x = 0.57;
	t.x = tan(k.x);
	printf("tan(%.20f) = %.20f = %020llx\n", k.x, t.x, t.y);
}
