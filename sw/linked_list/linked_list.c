#include <stdio.h>
#include <stdint.h>
#include <inttypes.h>
#include <malloc.h>
#include <string.h>

#include <thuasrv32.h>

/* Frequency of the DE0-CV board */
#ifndef F_CPU
#define F_CPU (50000000UL)
#endif
/* Transmission speed */
#ifndef BAUD_RATE
#define BAUD_RATE (9600ULL)
#endif

/* The stucture of the node */
#define NAMLEN (20)
typedef struct node
{
	char name[NAMLEN];
	int age;
	struct node *next;
} node_t;


node_t *head = NULL;


/* The main... */
int main(void)
{
	/* Pointer to node */
	node_t *current, *prev;

	/* A buffer for names */
	char buffer[NAMLEN+26];

	int count = 0;


	uart1_init(BAUD_RATE, UART_CTRL_NONE);

	uart1_puts("\r\n\r\nLinked list test\r\n");

	sprintf(buffer, "Size of node: %u\r\n", sizeof(node_t));
	uart1_puts(buffer);

	/* Create head (first) node */
	if ((head = malloc(sizeof(node_t))) == NULL) {
		uart1_puts("Cannot allocate node!\r\n");
		return -1;
	}

	/* Head node exists */
	strncpy(head->name, "Evan", NAMLEN);
	head->age = 25;
	head->next = NULL;

	/* Create new (second) node */
	if ((current = malloc(sizeof(node_t))) == NULL) {
		uart1_puts("Cannot allocate node!\r\n");
		return -1;
	}

	/* Current node exists */
	strncpy(current->name, "Billie", NAMLEN);
	current->age = 18;
	current->next = NULL;

	/* Let head->next point to new node */
	head->next = current;
	/* Save current */
	prev = current;

	/* Create new (third) node */
	if ((current = malloc(sizeof(node_t))) == NULL) {
		uart1_puts("Cannot allocate node!\r\n");
		return -1;
	}

	/* Current node exists */
	strncpy(current->name, "Sam", NAMLEN);
	current->age = 29;
	current->next = NULL;

	/* Let prev->next point to new node */
	prev->next = current;
	/* Save current */
	prev = current;

	/* Create new (fourth) node */
	if ((current = malloc(sizeof(node_t))) == NULL) {
		uart1_puts("Cannot allocate node!\r\n");
		return -1;
	}

	/* Current node exists */
	strncpy(current->name, "Hendrik", NAMLEN);
	current->age = 54;
	current->next = NULL;

	/* Let prev->next point to new node */
	prev->next = current;
	/* Save current */
	prev = current;

	/* Print the list */
	for (current = head; current != NULL; current = current->next) {
		sprintf(buffer, "@: %p, name: %s, age: %d\r\n", current, current->name, current->age);
		uart1_puts(buffer);
	}

	/* Find end of list */
	for (current = head; current != NULL; current = current->next) {
		prev = current;
	}
	/* prev points to the last node */
	
	sprintf(buffer, "Last node @: %p\r\n", prev);
	uart1_puts(buffer);
	sprintf(buffer, "Name: %s, age: %d\r\n", prev->name, prev->age);
	uart1_puts(buffer);

	/* Fill up all memory, but don't penetrate the stack */
	while (1) {
		prev = current;
		if ((current = malloc(sizeof(node_t))) == NULL) {
			uart1_puts("Cannot allocate more nodes!\r\n");
			break;
		}
		count++;
	}

	sprintf(buffer, "Total of %d nodes\r\n", count);
	uart1_puts(buffer);
	sprintf(buffer, "Last node @: %p\r\n", prev);
	uart1_puts(buffer);

	return 0;
}
