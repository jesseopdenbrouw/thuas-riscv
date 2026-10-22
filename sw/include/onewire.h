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
/* Receive one byte */
uint32_t onewire1_receive_byte(void);
/* Receive multiple bytes */
uint32_t onewire1_receive(uint8_t data[], uint32_t len);
/* Calculate 1-Wire CRC on per byte basis */
uint8_t onewire1_calccrc_byte(uint8_t data);
uint8_t onewire1_calccrc(uint8_t data[], uint32_t len);

#define ONEWIRE_RCIE     (1 << 3)
#define ONEWIRE_TCIE     (1 << 4)
#define ONEWIRE_PCIE     (1 << 5)
#define ONEWIRE_RESET    (1 << 6)

#define ONEWIRE_RC       (1 << 3)
#define ONEWIRE_TC       (1 << 4)
#define ONEWIRE_PC       (1 << 5)
#define ONEWIRE_PRESENCE (1 << 6)
#define ONEWIRE_BUSY     (1 << 7)

#ifdef __cplusplus
}
#endif

#endif
