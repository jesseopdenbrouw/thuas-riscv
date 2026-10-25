/*
 * onewire.h - definitions for the one-wire device of the THUAS processor
 */

#ifndef _ONEWIRE_H
#define _ONEWIRE_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Send a reset pulse to the device, returns presence */
uint32_t onewire1_reset(void);
/* Transmit one byte */
uint32_t onewire1_transmit_byte(uint32_t data);
/* Transmit multiple bytes */
uint32_t onewire1_transmit(uint8_t data[], uint32_t len);
/* Receive one byte */
uint32_t onewire1_receive_byte(void);
/* Receive multiple bytes */
uint32_t onewire1_receive(uint8_t data[], uint32_t len);
/* Calculate 1-Wire CRC8 for one byte */
uint8_t onewire1_calccrc_byte(uint8_t data);
/* Calculate 1-Wire CRC8 for multiple bytes */
uint8_t onewire1_calccrc(uint8_t data[], uint32_t len);
/* Transmit one bit (lsb) */
uint32_t onewire1_transmit_bit(uint32_t bit);
/* Receive one bit (lsb) */
uint32_t onewire1_receive_bit(void);
/* Find 'first' device on the bus, ROM code is present in r[] */
uint32_t onewire1_findfirst(uint8_t r[]);
/* Find 'next' device on the bus, ROM code is present in r[] */
uint32_t onewire1_findnext(uint8_t r[]);
/* Setup the search to find the device type 'family_code' on the next call */
void onewire1_targetsetup(uint8_t family_code);
/* Setup the search to skip the current device type on the next call */
void onewire1_familyskipsetup(void);


#define ONEWIRE_RCIE     (1 << 3)
#define ONEWIRE_TCIE     (1 << 4)
#define ONEWIRE_PCIE     (1 << 5)
#define ONEWIRE_RESET    (1 << 6)
#define ONEWIRE_ONEBIT   (1 << 7)

#define ONEWIRE_RC       (1 << 3)
#define ONEWIRE_TC       (1 << 4)
#define ONEWIRE_PC       (1 << 5)
#define ONEWIRE_PRESENCE (1 << 6)
#define ONEWIRE_BUSY     (1 << 7)

#ifdef __cplusplus
}
#endif

#endif
