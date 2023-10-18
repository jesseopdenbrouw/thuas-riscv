//
// SSD1315 (or SSD1306) implementation
//
// (c) 20212,  J. op den Brouw

// Since the device is using I2C, no reads
// of the SSD1315 RAM can be done

#ifndef INC_SSD1315_H_
#define INC_SSD1315_H_

#include <stdint.h>

// Address of SSD1315
#define SSD1315_ADDR (0x3C << 1)

// Error status of SSD1315
typedef enum {SSD1315_OK, SSD1315_ERR} ssd1315_status_t;

// Initialize the SSD1315
ssd1315_status_t ssd1315_init(void);
// Set (x,y) position, note: y is row by 8
ssd1315_status_t ssd1315_setpos(uint8_t x, uint8_t y);
// Fill the screen with data, 0x00 = all clear, 0xFF = all set
ssd1315_status_t ssd1315_fillscreen(uint8_t fill);
// Print a character (x,y), x increses automatically
ssd1315_status_t ssd1315_putchar(char ch);
// Put a string, using ssd1315_putchar()
ssd1315_status_t ssd1315_puts(char *s);
// Set the contrast (0x00 - 0xFF)
ssd1315_status_t ssd1315_setcontrast(uint8_t contrast);

#endif /* INC_SSD1315_H_ */
