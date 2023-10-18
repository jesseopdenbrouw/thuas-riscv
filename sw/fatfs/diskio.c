/*-----------------------------------------------------------------------*/
/* Low level disk I/O module SKELETON for FatFs     (C)ChaN, 2019        */
/*-----------------------------------------------------------------------*/
/* If a working storage control module is available, it should be        */
/* attached to the FatFs via a glue function rather than modifying it.   */
/* This is an example of glue functions to attach various exsisting      */
/* storage control modules to the FatFs module with a defined API.       */
/*-----------------------------------------------------------------------*/

#include "ff.h"			/* Obtains integer types */
#include "diskio.h"		/* Declarations of disk functions */

#include <stdio.h>

/* begin THUAS RISC-V specific */
#include <thuasrv32.h>
#include "sdcard.h"
#define DISKIO_DEBUG (0)
/* end THUAS RISC-V specific */

/* Definitions of physical drive number for each drive */
#define DEV_MMC		0	/* Example: Map MMC/SD card to physical drive 0 */
#define DEV_RAM		1	/* Example: Map Ramdisk to physical drive 1 */
#define DEV_USB		2	/* Example: Map USB MSD to physical drive 2 */


/*-----------------------------------------------------------------------*/
/* Get Drive Status                                                      */
/*-----------------------------------------------------------------------*/

DSTATUS disk_status (
	BYTE pdrv		/* Physical drive nmuber to identify the drive */
)
{
#if DISKIO_DEBUG == 1
	char buffer[40];

	snprintf(buffer, sizeof buffer, "status called: pdrv = %d: ", pdrv);
	usart_puts(buffer);
#endif

	//int result;

	switch (pdrv) {
	case DEV_MMC :
		if (SD_getstatus() == 1) {
#if DISKIO_DEBUG == 1
			usart_puts("ok\r\n");
#endif
			return FR_OK;
		}
#if DISKIO_DEBUG == 1
		usart_puts("no disk\r\n");
#endif
		return STA_NODISK;
	}
#if DISKIO_DEBUG == 1 
	usart_puts("no drive\r\n");
#endif
	return STA_NOINIT;
}



/*-----------------------------------------------------------------------*/
/* Inidialize a Drive                                                    */
/*-----------------------------------------------------------------------*/

DSTATUS disk_initialize (
	BYTE pdrv		/* Physical drive nmuber to identify the drive */
)
{
#if DISKIO_DEBUG == 1
	char buffer[60];

	snprintf(buffer, sizeof buffer, "init called: pdrv = %d: ", pdrv);
	usart_puts(buffer);
#endif

	//DSTATUS stat = FR_OK;
	//int result;

	switch (pdrv) {
	case DEV_MMC :

		if (SD_initialize() == SD_ERROR) {
#if DISKIO_DEBUG == 1
			usart_puts("no disk\r\n");
#endif
			return STA_NODISK;
		}
#if DISKIO_DEBUG == 1
		usart_puts("ok\r\n");
#endif
		return FR_OK;
	}
#if DISKIO_DEBUG == 1
	usart_puts("no init\r\n");
#endif
	return STA_NOINIT;
}



/*-----------------------------------------------------------------------*/
/* Read Sector(s)                                                        */
/*-----------------------------------------------------------------------*/

DRESULT disk_read (
	BYTE pdrv,		/* Physical drive nmuber to identify the drive */
	BYTE *buff,		/* Data buffer to store read data */
	LBA_t sector,		/* Start sector in LBA */
	UINT count		/* Number of sectors to read */
)
{
	//DRESULT res = RES_OK;
	//int result;

#if DISKIO_DEBUG == 1
	char buffer[60];

	snprintf(buffer, sizeof buffer, "read: pdrv = %d, sector = %d, count = %d     \r\n", pdrv, sector, count);
	usart_puts(buffer);
#endif

	switch (pdrv) {
	case DEV_MMC :
		uint32_t ret;
		for (uint32_t i = 0; i < count; i++) {
			ret = SD_readsector(sector, buff);
			if (ret == SD_ERROR) {
				return RES_ERROR;
			}
			sector++;
			buff += SD_getsectorsize();
		}
		return RES_OK;
	}

	return RES_PARERR;
}



/*-----------------------------------------------------------------------*/
/* Write Sector(s)                                                       */
/*-----------------------------------------------------------------------*/

#if FF_FS_READONLY == 0

DRESULT disk_write (
	BYTE pdrv,		/* Physical drive nmuber to identify the drive */
	const BYTE *buff,	/* Data to be written */
	LBA_t sector,		/* Start sector in LBA */
	UINT count		/* Number of sectors to write */
)
{
	//DRESULT res = RES_OK;
	//int result;

#if DISKIO_DEBUG == 1
	char buffer[60];

	snprintf(buffer, sizeof buffer, "write: pdrv = %d, sector = %d, count = %d\r\n", pdrv, sector, count);
	usart_puts(buffer);
#endif

	switch (pdrv) {
	case DEV_MMC :
		uint32_t ret;
		for (uint32_t i = 0; i < count; i++) {
			ret = SD_writesector(sector, buff);
			if (ret == SD_ERROR) {
				return RES_ERROR;
			}
			sector++;
			buff += SD_getsectorsize();
		}
		return RES_OK;
	}

	return RES_PARERR;
}

#endif


/*-----------------------------------------------------------------------*/
/* Miscellaneous Functions                                               */
/*-----------------------------------------------------------------------*/

DRESULT disk_ioctl (
	BYTE pdrv,		/* Physical drive nmuber (0..) */
	BYTE cmd,		/* Control code */
	void *buff		/* Buffer to send/receive control data */
)
{
	//DRESULT res = RES_PARERR;
	//int result;

#if DISKIO_DEBUG == 1
	char buffer[40];

	snprintf(buffer, sizeof buffer, "ioctl: pdrv = %d\n, cmd: %d", pdrv, cmd);
#endif

	switch (pdrv) {
	case DEV_MMC :
		/* Currently not supported */
		return RES_PARERR;
	}

	return RES_PARERR;
}

