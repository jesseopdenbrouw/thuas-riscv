#include <ctype.h>
#include <stdint.h>

#include <thuasrv32.h>

/* Parse decimal string from s, ppchar return position after the decimal string */
int32_t parsedec(char *s, char **ppchar) {

	uint32_t v = 0;
	int neg = 0;

	while (isspace((int) *s)) {
		s++;
	}

	if (*s == '-') {
		neg = 1;
		s++;
	}

	while (isdigit((int) *s)) {
		v = v * 10 + *s - '0';
		s++;
	}

	if (ppchar != NULL) {
		*ppchar = s;
	}
	
	return neg ? -v : v;
}
