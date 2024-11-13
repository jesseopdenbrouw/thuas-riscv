/*
 * prints the THUAS RV32 logo
 */

#include <thuasrv32.h>

void printlogo(void)
{
	uart1_puts("\r\n"
	           "___       _  __    _ \\ /__ __ \r\n"
	           " | |_|| ||_|(_ ---|_) V __) _)\r\n"
	           " | | ||_|| |__)   | \\   __)/__\r\n"
	           );
}
