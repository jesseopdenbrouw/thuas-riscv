/*
 * spi.h -- definitions for the SPIs
 */

#ifndef _SPI_H
#define _SPI_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Initialize SPI1 */
void spi1_init(uint32_t value);
/* Read/write data to SPI1 */
uint32_t spi1_transfer(uint32_t data);
/* Transmit a buffer of uint8_t to SPI1 */
void spi1_transmit(uint8_t *buf, uint32_t len);
/* Receive a buffer of uint8_t from SPI1 */
void spi1_receive(uint8_t *buf, uint32_t len, uint32_t dummy);
/* Transmit to and receive from uint8_t buffers using SPI1 */
void spi1_transmit_receive(uint8_t *buft, uint8_t *bufr, uint32_t len);
/* SPI1 software-enabled Chip Select
 * This is an empty stub. User must
 * supply a function which uses a
 * port pin */
__attribute__((weak)) void spi1_csenable(void);
__attribute__((weak)) void spi1_csdisable(void);

/* Initialize SPI2 */
void spi2_init(uint32_t value);
/* Read/write data to SPI1 */
uint32_t spi2_transfer(uint32_t data);
/* SPI2 software-enabled Chip Select
 * This is an empty stub. User must
 * supply a function which uses a
 * port pin */
__attribute__((weak)) void spi2_csenable(void);
__attribute__((weak)) void spi2_csdisable(void);

/* For both SPI1 and SPI2 */
#define SPI_MODE0  (0 << 1)
#define SPI_MODE1  (1 << 1)
#define SPI_MODE2  (2 << 1)
#define SPI_MODE3  (3 << 1)
#define SPI_SIZE8  (0 << 4)
#define SPI_SIZE16 (1 << 4)
#define SPI_SIZE24 (2 << 4)
#define SPI_SIZE32 (3 << 4)

#define SPI_PRESCALER0 (0 << 8)
#define SPI_PRESCALER1 (1 << 8)
#define SPI_PRESCALER2 (2 << 8)
#define SPI_PRESCALER3 (3 << 8)
#define SPI_PRESCALER4 (4 << 8)
#define SPI_PRESCALER5 (5 << 8)
#define SPI_PRESCALER6 (6 << 8)
#define SPI_PRESCALER7 (7 << 8)

/* For SPI1 only */
#define SPI_TIE    (1 << 3)
#define SPI_CSSETUP(A) ((A & 0xff) << 20)
#define SPI_CSHOLD(A)  ((A & 0xff) << 12)

#ifdef __cplusplus
}
#endif

#endif
