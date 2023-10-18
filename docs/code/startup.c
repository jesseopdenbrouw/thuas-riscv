/*
 * Startup file for THUAS RISC-V bare metal processor
 *
 * (c) 2023, Jesse E.J. op den Brouw <J.E.J.opdenBrouw@hhs.nl>
 *
 * */

#include <string.h>
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>

/* bss and rom data copy with pointers
 * in registers. Faster code, but less
 * visible in RAM variables */
#define WITH_REGISTER
//#define WITH_DESTRUCTORS

/* Find the name of the program */
#ifndef PROG_NAME
#define PROG_NAME __FILE__
#endif

/* Import symbols from the linker */
extern uint8_t _sbss, _ebss;
extern uint8_t _sdata, _edata;
extern uint8_t _sidata;
extern uint8_t _srodata, _erodata;

/* Declare the `main' function */
int main(int argc, char *argv[], char *envp[]);

/* Declare the construcor and destructor function */
/* Declare the pre-init universal handler */
void __libc_init_array(void);
void __libc_fini_array(void);
void pre_init_universal_handler(void);

/* argv array for main */
char *argv[] = {
#ifndef NO_ARGC_ARGV
		PROG_NAME,
		"THUAS RISC-V RV32IM bare metal processor",
		"The Hague University of Applied Sciences",
		"Department of Electrical Engineering",
		"J.E.J. op den Brouw",
#endif
		NULL};
/* Calculate argc */
#define argc (sizeof(argv)/sizeof(argv[0])-1)

/* The startup code must be placed at the begin of the ROM */
/* and doesn't need a stack frame of pushed registers */
/* The linker will place this function at the beginning */
/* of the code (text) */
__attribute__((section(".text.start_up_code_c")))
__attribute__((naked))
void _start(void)
{

	/* These assembler instructions set up the Global Pointer
	 * and the Stack Pointer and set the mtvec to the start
	 * address of the pre-init interrupt handler. This will
	 * catch pre-init traps. Mostly because of a bug. */
     __asm__ volatile (".option push;"
	                   ".option norelax;"
	                   "la    t0, pre_init_universal_handler;"
	                   "csrw  mtvec,t0;"
	                   "la    gp, __global_pointer$;"
	                   "la    sp, __stack_pointer$;"
	                   ".option pop"
	                   : /* output: none */
	                   : /* input: none */
	                   : /* clobbers: none */);

#ifdef WITH_REGISTER
	register uint8_t *pStart;
	register uint8_t *pEnd;
	register uint8_t *pdRom;
#else
	volatile uint8_t *pStart;
	volatile uint8_t *pEnd;
	volatile uint8_t *pdRom;
#endif

	/* Initialize the bss with 0 */
	pStart = &_sbss;
	pEnd = &_ebss;
	while (pStart < pEnd) {
		*pStart = 0x00;
		*pStart++;
	}

	/* Copy the ROM-placed RAM init data to the RAM */
	pStart = &_sdata;
	pEnd = &_edata;
	pdRom = &_sidata;
	while (pStart < pEnd) {
		*pStart = *pdRom;
		pStart++;
		pdRom++;
	}

	/* Call the constructors */
	__libc_init_array();

	/* At this point, the trap handler is not set up
	 * properly. Also, the external timer is not set
	 * up properly. This must be done in main() */

	/* Call main */
	int ret = main(argc, argv, NULL);

#ifdef WITH_DESTRUCTORS
	/* Call the destructors */
	__libc_fini_array();
#endif

	/* Stop execution */
	exit(ret);
}

/* pre-init trap handler. Here to catch initialization errors */
__attribute__(( used ))
__attribute__ ((interrupt))
void pre_init_universal_handler(void)
{
	while (1);
}

