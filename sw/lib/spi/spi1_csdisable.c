/*
 * spi1_csdisable.c -- CS disable for SPI1 (weak)
 *
 */

#include <thuasrv32.h>

/* The user must specify the correct port pin
 * for software-enabled Chip Select */
__attribute__((weak)) void spi1_csdisable(void)
{
}
