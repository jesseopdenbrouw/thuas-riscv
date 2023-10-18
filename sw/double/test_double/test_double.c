/*
 * test_double.c -- program to generate contents
 *                  of double variabels in hexadecimal
 *
 * compile with: gcc -o test_double test_double.c
 *
 * Note: RISC-V must be Little Endian
 *
 */

#include <stdio.h>

union {
	double x;
	unsigned long long int y;
} t;

int main(void) {


	t.x = 1.0;
	printf("%.16f = %016llx\n", t.x, t.y);

	t.x = t.x + t.x;
	printf("%.16f = %016llx\n", t.x, t.y);

	t.x = t.x * -3.0;
	printf("%.16f = %016llx\n", t.x, t.y);

	t.x = t.x / 3.0;
	printf("%.16f = %016llx\n", t.x, t.y);

	t.x = 0.6;
	printf("%.20f = %016llx\n", t.x, t.y);

	t.x = t.x - 0.31;
	printf("%.20f = %016llx\n", t.x, t.y);
}
