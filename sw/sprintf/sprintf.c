/*
 * sprintf - program to test sprintf
 *           for use in the simulator
 *
 * note that linker option `-u _printf_float` is needed
 * to print out floating point variables
 *           
 */

#include <stdio.h>

volatile char str[60] = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";

volatile int i = 1234;

volatile double j = 1.2;

volatile unsigned long long int k = 0x7fffffffffff;

int main(void)
{
	/* Note: long long cannot be printed */
	sprintf((char *)str, "| %d | %f | %llu |", i, j, k);
}

