/*
 * For use in the simulator
 */

#include <stdio.h>
#include <string.h>

int main(void) {

	/* The strinf */
	volatile char str[] = "Hello this is a string";

	/* Make a non-volatile buffer */
	volatile char to[100];

	/* Get the string length */
	volatile int x = strlen(str);

	/* Copy the string */
	strcpy((char *)to, str);

	/* Concatenate a string */
	strcat(to, "! And it works!");

	/* Get string compare */
	x = strcmp("Hello", str);

	return x;
}
