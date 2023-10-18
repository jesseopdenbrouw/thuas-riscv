/*
 * i2c.h -- definitions for the I2C
 */

#ifndef _I2C_H
#define _I2C_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Initialize I2C1 */
void i2c1_init(uint32_t value);
/* Send address to I2C1 */
uint32_t i2c1_transmit_address(uint8_t address);
/* Send address only to I2C1 */
uint32_t i2c1_transmit_address_only(uint8_t address);
/* Send byte to I2C1 */
uint32_t i2c1_transmit_byte(uint8_t data);
/* Transmit a buffer of uint8_t to I2C1 */
uint32_t i2c1_transmit(uint8_t address, uint8_t *buf, uint32_t len);
/* Receive a byte */
uint8_t i2c1_receive_byte(void);
/* Receive a buffer of uint8_t from I2C1 */
uint32_t i2c1_receive(uint8_t address, uint8_t *buf, uint32_t len);

/* Initialize I2C2 */
void i2c2_init(uint32_t value);
/* Send address to I2C2 */
uint32_t i2c2_transmit_address(uint8_t address);
/* Send address only to I2C2 */
uint32_t i2c2_transmit_address_only(uint8_t address);
/* Send byte to I2C2 */
uint32_t i2c2_transmit_byte(uint8_t data);
/* Transmit a buffer of uint8_t to I2C2 */
uint32_t i2c2_transmit(uint8_t address, uint8_t *buf, uint32_t len);
/* Receive a byte */
uint8_t i2c2_receive_byte(void);
/* Receive a buffer of uint8_t from I2C2 */
uint32_t i2c2_receive(uint8_t address, uint8_t *buf, uint32_t len);

/* Due to rounding toward 0, some speeds may be a bit to high */
#define I2C_PRESCALER_FM(A) (((A/3UL/400000UL)-1) << 16)
#define I2C_PRESCALER_SM(A) (((A/2UL/100000UL)-1) << 16)
#define I2C_FAST_MODE     (1 << 2)
#define I2C_STANDARD_MODE (0 << 2)
#define I2C_TCIE          (1 << 3)
#define I2C_MACK          (1 << 11)
#define I2C_HARDSTOP      (1 << 10)
#define I2C_START         (1 << 9)
#define I2C_STOP          (1 << 8)
#define I2C_BUSY          (1 << 6)
#define I2C_AF            (1 << 5)
#define I2C_TC            (1 << 3)
#define I2C_TRANS         (1 << 2)
#define I2C_READ          (1)
#define I2C_WRITE         (0)


#ifdef __cplusplus
}
#endif

#endif
