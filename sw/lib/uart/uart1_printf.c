
#include <stdarg.h>

#include <thuasrv32.h>

/* 256 characters should be enough */
#define BUFFER_SIZE (256)

/* If you want to print floating point numbers, you
 * have to pass `-u _printf_float` to the linker. */
int uart1_printf(const char *format, ...)
{
	char buffer[BUFFER_SIZE];
	va_list args;
	int n;

	va_start(args, format);
	n = vsnprintf(buffer, sizeof buffer, format, args);
	va_end(args);
	uart1_puts(buffer);
	return n;
}
