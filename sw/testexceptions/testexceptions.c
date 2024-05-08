/*
 *
 * testexceptions - test various exceptions
 *
 */



#include <thuasrv32.h>

/* Marking the spot to return after instruction access fault */
void here(void);
/* Marking the spot to return after instruction misaligned fault */
void here2(void);

/* The trap handler */
void trap_handler(void);

__attribute__ ((naked))
__attribute__ ((noinline))
void ret(void) {
}

int main(void) {

	/* Initialize the UART1 */
	uart1_init(BAUD_RATE, UART_CTRL_EN);

	/* Set the entry point of the trap handler */
	set_mtvec(trap_handler, TRAP_DIRECT_MODE);

	/* Welcome */
	uart1_puts("\r\nException test program\r\n");

	/* ECALL */
	//uart1_puts("ECALL\r\n");
	asm volatile ("ecall" :::);

	/* EBREAK */
	//uart1_puts("EBREAK\r\n");
	asm volatile ("ebreak" :::);

	/* Unallocated memory load */
	//uart1_puts("Unallocated memory load\r\n");
	asm volatile ("la t0,0x30000000;"
                  "lb t1,0(t0);"
                  ::: "t0");

	/* Unallocated memory store */
	//uart1_puts("Unallocated memory store\r\n");
	asm volatile ("la t0,0x30000000;"
                  "sb t1,0(t0);"
                  ::: "t0");

	/* Misaligned halfword load */
	//uart1_puts("Misaligned halfword memory load\r\n");
	asm volatile ("la t0,0x20000001;"
                  "lh t1,0(t0);"
                  ::: "t0");

	/* Misaligned halfword store */
	//uart1_puts("Misaligned halfword memory store\r\n");
	asm volatile ("la t0,0x20000001;"
                  "sh t1,0(t0);"
                  ::: "t0");
	
	/* Misaligned word load */
	//uart1_puts("Misaligned word memory load\r\n");
	asm volatile ("la t0,0x20000001;"
                  "lw t1,0(t0);"
                  ::: "t0");

	/* Misaligned word store */
	//uart1_puts("Misaligned word memory store\r\n");
	asm volatile ("la t0,0x20000001;"
                  "sw t1,0(t0);"
                  ::: "t0");

	/* Illegal instruction */
	//uart1_puts("Illegal instruction\r\n");
	asm volatile (".word 0x00000000" :::);

	/* Instruction access error */
	/* `here` marks the spot to return to after the trap */
	asm volatile (".global here;"
                  "la t0,0x20000000;"
                  "jr 0(t0);"
				  "here: nop;"
                  ::: "t0"); 

	/* Instruction misaligned error */
	/* `here2` marks the spot to return to after the trap */
	asm volatile (".global here2;"
                  "li t0,0x00000001;"
				  "jr 0(t0);"
				  "here2: nop;"
                  ::: "t0");

	uart1_puts("Done\r\n");

	while(1);

}

__attribute__ ((interrupt))
void trap_handler(void)
{
	register uint32_t mcause = csr_read(mcause);
	register uint32_t mepc = csr_read(mepc);
	register uint32_t mtval = csr_read(mtval);

	uart1_puts(" Exception--> mcause: ");
	printhex(mcause, 8);
	uart1_puts(", mepc: ");
	printhex(mepc, 8);
	uart1_puts(", mtval: ");
	printhex(mtval, 8);

	uart1_puts(", ");
	switch (mcause) {
		case 0: uart1_puts("Instruction address misaligned");
				break;
		case 1: uart1_puts("Instruction access fault");
				break;
		case 2: uart1_puts("Illegal instruction");
				break;
		case 3: uart1_puts("Breakpoint (ebreak)");
				break;
		case 4: uart1_puts("Load address misaligned");
				break;
		case 5: uart1_puts("Load access fault");
				break;
		case 6: uart1_puts("Store address misaligned");
				break;
		case 7: uart1_puts("Store access fault");
				break;
		case 11: uart1_puts("Environment call from M-mode (ecall)");
				break;
		default: uart1_puts("No description");
				break;
	}
	uart1_puts("\r\n");

	/* If the exception was due to an instruction access fault,
     * return to the spot marked `here` */
	if (mcause == 1) {
		mepc = (uint32_t) here;
	/* If the exception was due to an instruction misaligned fault,
     * return to the spot marked `here2` */
	} else if (mcause == 0) {
		mepc = (uint32_t) here2;
	} else {
		mepc += 4;
	}

	csr_write(mepc, mepc);

}
