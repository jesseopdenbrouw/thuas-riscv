/*
 * global.c - check initialization of globals en static locals
 *            for use in the simulator
 *
 */

/* Frequency of the DE0-CV board */
#ifndef F_CPU
#define F_CPU (50000000UL)
#endif
/* Transmission speed */
#ifndef BAUD_RATE
#define BAUD_RATE (115200UL)
#endif


#include <errno.h>

int ary[20] = { 2, 4, 5, 6, 9};

int x = 0xffff;

int y, w;

const volatile int c = 10;

int main(void) {


	char buf[20];

	static int jaja = -2;

	buf[0] = 'A';

	errno = -1;

	x = x + 1;

	y = 0x12345678;

	w = 0x90abcdef;

	x = c;

	errno = 0;

	jaja++;

	return 0;
}
