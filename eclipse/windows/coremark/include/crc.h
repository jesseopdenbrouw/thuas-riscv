/*
 * crc.h -- definitions for the CRC unit
 */

#ifndef _CRC_H
#define _CRC_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Initialize the CRC unit */
void crc_init(uint32_t ctrl, uint32_t poly, uint32_t sreg);
/* Write one datum, 8 bits */
void crc_write(uint8_t data);
/* Write a block of data */
void crc_block(uint8_t *block, uint32_t len);
/* Get calculated CRC */
uint32_t crc_get(void);

#define CRC_TC (1 << 3)

#define CRC_SIZE32   (0 << 4)
#define CRC_SIZE24   (1 << 4)
#define CRC_SIZE16   (2 << 4)
#define CRC_SIZE8    (3 << 4)

#ifdef __cplusplus
}
#endif

#endif
