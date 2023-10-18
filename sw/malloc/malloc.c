/*
 * malloc.c - Test the malloc et al. functions
 *            For use in the simulator
 */

#include <malloc.h>

int main(void) {

	/* seems to work */
	char *pchar;

	pchar = (char *) malloc(100);

	for (int i = 0; i < 100; i++) {
		pchar[i] = 'A';
	}

	free(pchar);

	pchar = (char *) malloc(50);

	for (int i = 0; i < 50; i++) {
		pchar[i] = 'A' + i;
	}

	free(pchar);

	/* seems to work */
	int *pint;

	pint = (int *) malloc(100);

	for (int i = 0; i < 25; i++) {
		pint[i] = -1;
	}

	/* seems to work */
	pint = (int *) realloc(pint, 120);

	for (int i = 0; i < 25; i++) {
		pint[i] = -1000;
	}

	free(pint);

	/* seems to work */
	int *pintca;

	pintca = (int *) calloc(25, sizeof(int));

	for (int i = 0; i < 25; i++) {
		pintca[i] = 0x11111111;
	}

	return 0;
}
