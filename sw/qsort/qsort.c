// C program to sort integer array
// using qsort with function pointer

#include <stdio.h>
#include <string.h>
#include <stdlib.h>

/* Load definitions */
#include <thuasrv32.h>

#ifndef F_CPU
#define F_CPU (50000000UL)
#endif
#ifndef BAUD_RATE
#define BAUD_RATE (9600UL)
#endif


int compare(const void* numA, const void* numB)
{
    const int *num1 = (const int*) numA;
    const int *num2 = (const int*) numB;

    if (*num1 > *num2) {
        return 1;
    }
    else {
        if (*num1 == *num2)
            return 0;
        else
            return -1;
    }
}

int main()
{
	/* The array to sort */
    volatile int arr[] = { 0x50, 0x30, 0x20, 0x10, 0x60, 0xa0, 0x40, 0xb0 };
	char buffer[10];

	uart1_init(BAUD_RATE, UART_CTRL_NONE);

	/* Print the unsorted array */
	for (int i = 0; i < sizeof arr / sizeof arr[0]; i++) {
		snprintf(buffer, sizeof buffer, "0x%02x ", arr[i]);
		uart1_puts(buffer);
	}
	uart1_puts("\r\n");

	/* Sort the array */
	qsort((void *)arr, sizeof arr / sizeof arr[0], sizeof(int), compare);

	/* Print the sorted array */
	for (int i = 0; i < sizeof arr / sizeof arr[0]; i++) {
		snprintf(buffer, sizeof buffer, "0x%02x ", arr[i]);
		uart1_puts(buffer);
	}
	uart1_puts("\r\n");

    return 0;
}
