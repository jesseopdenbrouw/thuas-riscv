/*
 * print_hwversion - print formatted hardware version
 *
 */

#include <thuasrv32.h>

void printhwversion(void)
{
	uint32_t version;
	uint32_t tmp;

	/* Get hardware version */
	version = csr_read(mimpid);

	/* Print tens of major, only is not 0 */
	tmp = (version >> 28) & 0xf;
	if (tmp) {
		uart1_putc(tmp + '0');
	}
	/* Print units of major */
	tmp = (version >> 24) & 0xf;
	uart1_putc(tmp + '0');
	uart1_putc('.');

	/* Print tens of minor, only is not 0 */
	tmp = (version >> 20) & 0xf;
	if (tmp) {
		uart1_putc(tmp + '0');
	}
	/* Print units of minor */
	tmp = (version >> 16) & 0xf;
	uart1_putc(tmp + '0');
	uart1_putc('.');

	/* Print tens of subminor, only is not 0 */
	tmp = (version >> 12) & 0xf;
	if (tmp) {
		uart1_putc(tmp + '0');
	}
	/* Print units of minor */
	tmp = (version >> 8) & 0xf;
	uart1_putc(tmp + '0');
	uart1_putc('.');

	/* Print tens of patch, only is not 0 */
	tmp = (version >> 4) & 0xf;
	if (tmp) {
		uart1_putc(tmp + '0');
	}
	/* Print units of patch */
	tmp = (version >> 0) & 0xf;
	uart1_putc(tmp + '0');

}
