/*
 *
 * SD Card Communication
 *
 *
 */

#ifndef SDCARD_H
#define SDCARD_H

#include <stdint.h>
#include <ctype.h>
#include <stdio.h>

#include <thuasrv32.h>

/* Should be loaded by the Makefile */
#ifndef F_CPU
#define F_CPU (50000000UL)
#endif
#ifndef BAUD_RATE
#define BAUD_RATE (9600UL)
#endif

#define SD_SUCCESS  0
#define SD_ERROR    1

#if 0
/* Not public */
void SPI2_init(uint32_t speed);
void SPI2_csenable(void);
void SPI2_csdisable(void);
uint8_t SPI2_transfer(uint8_t what);
void SD_powerup();
void SD_command(uint8_t cmd, uint32_t arg, uint8_t crc);
uint8_t SD_readR1(void);
void SD_printR1(uint8_t r1);
uint8_t SD_CMD0(void);
void SD_readR37(uint8_t *res);
void SD_CMD8(uint8_t *res);
void SD_CMD58(uint8_t *res);
void SD_printR3(uint8_t *res);
uint8_t SD_CMD55(void);
uint8_t SD_ACMD41(void);
uint32_t SD_CMD910(uint8_t cmd, uint8_t *buf);
#endif
/* Public functions */
uint32_t SD_initialize(void);
uint32_t SD_readsector(uint32_t sector, uint8_t *buf);
uint32_t SD_writesector(uint32_t sector, const uint8_t *buf);
uint32_t SD_getsectorsize(void);
uint32_t SD_getcapacity(void);
uint32_t SD_getccs(void);
uint32_t SD_getspeed(void);
uint32_t SD_getcsdver(void);
uint32_t SD_getstatus(void);
#endif
