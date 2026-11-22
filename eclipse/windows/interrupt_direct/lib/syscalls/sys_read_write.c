#include <errno.h>
#include <stdio.h>
#include <signal.h>
#include <time.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <sys/times.h>

/* These are system call stubs for _read and _write.
 * The user can implement these by providing implementations
 * for __io_putchar and __io_getchar. By default, these
 * functions do nothing and return 0. */

/* User callable functions */
__attribute__((weak)) int __io_putchar(int ch) {
	return 0;
}

__attribute__((weak)) int __io_getchar(void) {
	return 0;
}

int _write(int fd, char* buf, int n) {

	for (int i = 0; i < n; i++) {
		__io_putchar(*buf++);
	}
	return n;
}

int _read(int fd, char *buf, int n) {

	for (int i = 0; i < n; i++) {
		*buf++ = __io_getchar();
	}
	return n;
}
