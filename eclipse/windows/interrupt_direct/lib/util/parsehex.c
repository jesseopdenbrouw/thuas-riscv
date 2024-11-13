#include <ctype.h>
#include <stdint.h>

#include <thuasrv32.h>

/* Parse hex string from s, ppchar return position after the hex string */
uint32_t parsehex(char *s, char **ppchar) {

	uint32_t v = 0;

	while (isspace((int) *s)) {
		s++;
	}

	while (isxdigit((int) *s)) {
		v <<= 4;
		if (isdigit((int) *s)) {
			v |= *s - '0';
		} else {
			v |= tolower(*s) - 'a' + 10;
		}
		s++;
	}

	if (ppchar != NULL) {
		*ppchar = s;
	}
	
	return v;
}
