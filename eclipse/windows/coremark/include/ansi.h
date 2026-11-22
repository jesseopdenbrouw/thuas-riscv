/*
 * ansi.h - header file for ANSI terminal escape sequences
 */

#ifndef _ANSI_H_
#define _ANSI_H_

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Screen size struct */
typedef struct {
	int width;
	int height;
} ansi_screensize_t;

/* Clear the screen and set cursor to (1, 1) */
void ansi_clear_screen(void);
/* Move cursor to (x, y) */
void ansi_move_cursor(int x, int y);
/* Disable cursor */
void ansi_disable_cursor(void);
/* Enable cursor */
void ansi_enable_cursor(void);
/* Set foreground color */
void ansi_set_color(uint32_t color);
/* Set background color */
void ansi_set_background(uint32_t color);
/* Reset rendition */
void ansi_reset_rendition(void);
/* Get screen size */
ansi_screensize_t ansi_get_screensize(void);

#define ANSI_BLACK  0
#define ANSI_RED    1
#define ANSI_GREEN  2
#define ANSI_YELLOW 3
#define ANSI_BLUE   4
#define ANSI_PURPLE 5
#define ANSI_CYAN   6
#define ANSI_WHITE  7

#ifdef __cplusplus
}
#endif

#endif

