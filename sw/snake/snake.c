/*
 * snake - play a game of snake
 */


#include <thuasrv32.h>

/* Terminal width and height */
#define WIDTH  80
#define HEIGHT 24
/* Maximum snake length */
#define MAX_SNAKE_LEN 100

typedef struct {
	int x, y;
} point_t;

point_t snake[MAX_SNAKE_LEN];
int snake_len;
point_t food, old_tail;
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
//void ansi_clear_screen(void) {
//	uart1_puts("\x1b[2J");
//	uart1_puts("\x1b[H");
//}

/* Move cursor to x,y position */
//void ansi_move_cursor(int x, int y) {
//	uart1_puts("\x1b[");
//	printdec(y);
//	uart1_putc(';');
//	printdec(x);
//	uart1_putc('H');
//}

//void ansi_disable_cursor(void)
//{
//	uart1_puts("\x1b[?25l");
//}

//void ansi_enable_cursor(void)
//{
//	uart1_puts("\x1b[?25h");
//}

/* Standard Pseudo-Random Number Generator (PRNG) for embedded systems */
uint32_t lfsr_rand(void) {
	rand_state ^= (rand_state << 13);
	rand_state ^= (rand_state >> 17);
	rand_state ^= (rand_state << 5);
	return rand_state;
}

/* Make food */
void spawn_food(void) {

	int retry;

	do {
		retry = 0;
		food.x = (lfsr_rand() % (WIDTH - 2)) + 2;
		food.y = (lfsr_rand() % (HEIGHT - 2)) + 2;
		for (int i = 0; i < snake_len; i++) {
			if (food.x == snake[i].x && food.y == snake[i].y) {
				retry = 1;
				break;
			}
		}
	} while (retry);
}

/* Draw border */
void draw_border(void)
{
	for (int y = 1; y <= HEIGHT; y++) {
		for (int x = 1; x <= WIDTH; x++) {
			if (y == 1 || y == HEIGHT || x == 1 || x == WIDTH) {
				ansi_move_cursor(x, y);
				uart1_putc('#');
			}
		}
	}
}

/* Initialize the game */
void init_game(void) {

	game_over = 0;
	score = 0;
	snake_len = 3;
	delay = 150;
	
	/* Start in the middle */
	snake[0] = (point_t){WIDTH / 2, HEIGHT / 2};
	snake[1] = (point_t){(WIDTH / 2) - 1, HEIGHT / 2};
	snake[2] = (point_t){(WIDTH / 2) - 2, HEIGHT / 2};

	for (int i = 3; i < MAX_SNAKE_LEN; i++) {
		snake[i] = (point_t) { 0, 0 };
	}
	
	/* Move Right initially */
	dir_x = 1;
	dir_y = 0;
	
	spawn_food();
	ansi_clear_screen();
	
	/* Draw border */
	draw_border();
}

/* Handle user input from keyboard */
void handle_input(void) {

	char input = uart1_getc_nonblocking();

	/* No key */
	if (input == 0) {
		return;
	}

	/* ^R redraws screen */
	if (input == 18) {
		ansi_clear_screen();
		ansi_disable_cursor();
		draw_border();
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
	old_tail = snake[snake_len - 1];
	
	/* Move body forward */
	for (int i = snake_len - 1; i > 0; i--) {
		snake[i] = snake[i - 1];
	}
	//snake[snake_len-1] = (point_t) {0, 0};
	
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
	
	/* Food collision */
	if (snake[0].x == food.x && snake[0].y == food.y) {
		score += 10;
		if (snake_len < MAX_SNAKE_LEN-1) {
			snake_len++;
		}
		if (delay > 100) {
			delay -= 2;
		}
		spawn_food();
	}
	/* Clear the old tail piece from the screen if we didn't grow */
	if (old_tail.x != 0 && old_tail.y != 0) {
		ansi_move_cursor(old_tail.x, old_tail.y);
		uart1_putc(' ');
	}
}

void render_game(void) {

	/* Draw Food */
	ansi_move_cursor(food.x, food.y);
	uart1_putc('*');
	
	/* Draw snake head */
	ansi_move_cursor(snake[0].x, snake[0].y);
	uart1_putc('O');
	
	/* Draw snake body */
	for (int i = 1; i < snake_len; i++) {
		if (snake[i].x != 0 && snake[i].y != 0) {
			ansi_move_cursor(snake[i].x, snake[i].y);
			uart1_putc('o');
		}
	}
}

int main(void) {

	uart1_init(BAUD_RATE, UART_CTRL_EN);

	ansi_disable_cursor();
	ansi_clear_screen();

	ansi_move_cursor(40, 10);
	uart1_puts( "   ____          __      \r\n");
	ansi_move_cursor(40, 11);
	uart1_puts( "  / __/__  ___ _/ /_____ \r\n");
	ansi_move_cursor(40, 12);
	uart1_puts( " _\\ \\/ _ \\/ _ `/  '_/ -_)\r\n");
	ansi_move_cursor(40, 13);
	uart1_puts( "/___/_//_/\\_,_/_/\\_\\\\__/ \r\n");
                         
	ansi_move_cursor(5, 8);
	uart1_puts("Play a game of Snake!");
	ansi_move_cursor(5, 15);
	uart1_puts("Press a key to start the game");
	uart1_getc();
	rand_state = csr_read(time);
	rand_state = (rand_state == 0) ? 1 : rand_state;

	while (1) {	
		init_game();
	
		while (1) {
			handle_input();
			update_game();
			if (game_over) {
				break;
			}
			render_game();
			delayms(delay);
		}
	
		/* Game Over message */
		ansi_clear_screen();
		ansi_move_cursor(5, 8);
		uart1_puts("GAME OVER!");
		ansi_move_cursor(5, 10);
		uart1_puts("Final Score: ");
		printdec(score);
		ansi_move_cursor(5, 15);
		uart1_puts("Press key to play another game or `q` to quit");
		if (uart1_getc() == 'q') {
			ansi_enable_cursor();
			ansi_clear_screen();
			while (1);
		};
	}
}

