#include <errno.h>
#include <stdio.h>
#include <signal.h>
#include <time.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <sys/times.h>

/* _sbrk must be provided to accomodate malloc et al. */

static uint8_t *__sbrk_heap_end = NULL;

void *_sbrk(ptrdiff_t incr)
{
	extern uint8_t _end; /* Symbol defined in the linker script */
	extern uint8_t __stack_pointer$; /* Symbol defined in the linker script */
	extern uint32_t __stack_size; /* Symbol defined in the linker script */
	const uint32_t stack_limit = (uint32_t)&__stack_pointer$ - (uint32_t)&__stack_size;
	const uint8_t *max_heap = (uint8_t *)stack_limit;
	uint8_t *prev_heap_end;

	/* Initialize heap end at first call */
	if (NULL == __sbrk_heap_end)
	{
		__sbrk_heap_end = &_end;
	}

	/* Protect heap from growing into the reserved stack space */
	if (__sbrk_heap_end + incr > max_heap)
	{
		errno = ENOMEM;
		return (void *)-1;
	}

	prev_heap_end = __sbrk_heap_end;
	__sbrk_heap_end += incr;

	return (void *)prev_heap_end;
}
