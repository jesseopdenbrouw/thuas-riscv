/*
 * snake - play a game of snake
 */


#include <thuasrv32.h>

/* Terminal width and height */
#define WIDTH  80
#define HEIGHT 25
/* Maximum snake length */
#define MAX_SNAKE_LEN 100

typedef struct {
	int x, y;
} point_t;

point_t snake[MAX_SNAKE_LEN];
int snake_len;
point_t food;
int dir_x, dir_y;
int game_over;
uint32_t score;
uint32_t delay;
uint32_t rand_state;

/* Get a character (if any) */
char uart1_getc_nonblocking(void) {
	if (uart1_hasreceived()) {
		return (char) uart1_getc();
	}
	return 0; 
}

/* Clear screen */
void clear_screen(void) {
	uart1_puts("\x1b[2J");
	uart1_puts("\x1b[H");
}

/* Move cursor to x,y position */
void move_cursor(int x, int y) {
	uart1_puts("\x1b[");
	printdec(y);
	uart1_putc(';');
	printdec(x);
	uart1_putc('H');
}

void disable_cursor(void)
{
	uart1_puts("\x1b[?25l");
}

void enable_cursor(void)
{
	uart1_puts("\x1b[?25h");
}

/* Standard Pseudo-Random Number Generator (PRNG) for embedded systems */
uint32_t lfsr_rand(void) {
	rand_state ^= (rand_state << 13);
	rand_state ^= (rand_state >> 17);
	rand_state ^= (rand_state << 5);
	return rand_state;
}

/* Make food */
void spawn_food(void) {
	food.x = (lfsr_rand() % (WIDTH - 2)) + 2;
	food.y = (lfsr_rand() % (HEIGHT - 2)) + 2;
}

/* Initialize the game */
void init_game(void) {

	game_over = 0;
	score = 0;
	snake_len = 3;
	delay = 250;
	
	/* Start in the middle */
	snake[0] = (point_t){WIDTH / 2, HEIGHT / 2};
	snake[1] = (point_t){(WIDTH / 2) - 1, HEIGHT / 2};
	snake[2] = (point_t){(WIDTH / 2) - 2, HEIGHT / 2};
	
	/* Move Right initially */
	dir_x = 1;
	dir_y = 0;
	
	spawn_food();
	clear_screen();
	
	/* Draw static borders once */
	for (int y = 1; y <= HEIGHT; y++) {
		for (int x = 1; x <= WIDTH; x++) {
			if (y == 1 || y == HEIGHT || x == 1 || x == WIDTH) {
				move_cursor(x, y);
				uart1_putc('#');
			}
		}
	}
}

/* Handle user input from keyboard */
void handle_input(void) {
	char input = uart1_getc_nonblocking();
	if (input == 0) {
		return;
	}
	
	/* Map W A S D keys, preventing the snake from reversing into itself */
	if ((input == 'w' || input == 'W') && dir_y != 1)  { dir_x = 0;  dir_y = -1; }
	if ((input == 's' || input == 'S') && dir_y != -1) { dir_x = 0;  dir_y = 1;  }
	if ((input == 'a' || input == 'A') && dir_x != 1)  { dir_x = -1; dir_y = 0;  }
	if ((input == 'd' || input == 'D') && dir_x != -1) { dir_x = 1;  dir_y = 0;  }
}

void update_game(void) {
	/* Keep track of the tail to clear its old position off the screen later */
	point_t old_tail = snake[snake_len - 1];
	
	/* Move body forward */
	for (int i = snake_len - 1; i > 0; i--) {
		snake[i] = snake[i - 1];
	}
	
	/* Move head */
	snake[0].x += dir_x;
	snake[0].y += dir_y;
	
	/* Wall collisions */
	if (snake[0].x <= 1 || snake[0].x >= WIDTH || snake[0].y <= 1 || snake[0].y >= HEIGHT) {
		game_over = 1;
		return;
	}
	
	/* Self collisions */
	for (int i = 1; i < snake_len; i++) {
		if (snake[0].x == snake[i].x && snake[0].y == snake[i].y) {
			game_over = 1;
			return;
		}
	}
	
	/* Food Collision */
	if (snake[0].x == food.x && snake[0].y == food.y) {
		score += 10;
		if (snake_len < MAX_SNAKE_LEN) {
			snake_len++;
		}
		if (delay > 100) {
			delay -= 2;
		}
		spawn_food();
	} else {
		/* Clear the old tail piece from the screen if we didn't grow */
		move_cursor(old_tail.x, old_tail.y);
		uart1_putc(' ');
	}
}

void render_game(void) {

	/* Draw Food */
	move_cursor(food.x, food.y);
	uart1_putc('*');
	
	/* Draw snake head */
	move_cursor(snake[0].x, snake[0].y);
	uart1_putc('O');
	
	/* Draw snake body */
	for (int i = 1; i < snake_len; i++) {
		move_cursor(snake[i].x, snake[i].y);
		uart1_putc('o');
	}
}

int main(void) {

	uart1_init(BAUD_RATE, UART_CTRL_EN);

	disable_cursor();
	clear_screen();
	move_cursor(5, 8);
	uart1_puts("Play a game of snake!");
	move_cursor(5, 15);
	uart1_puts("Press a key to start the game");
	uart1_getc();
	rand_state = csr_read(time);

	while (1) {	
		init_game();
	
		while (!game_over) {
			handle_input();
			update_game();
			if (game_over) {
				break;
			}
			render_game();
			delayms(delay);
		}
	
		/* Game Over message */
		clear_screen();
		move_cursor(5, 8);
		uart1_puts("GAME OVER!");
		move_cursor(5, 10);
		uart1_puts("Final Score: ");
		printdec(score);
		move_cursor(5, 15);
		uart1_puts("Press key to continue");
		if (uart1_getc() == 'q') {
			enable_cursor();
			while (1);
		};
	}

}

