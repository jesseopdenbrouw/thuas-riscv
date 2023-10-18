/*
 * RISC-V RV32IM generic trap handler (vectored)
 *
 * (c) 2022, Jesse E.J. op den Brouw
 *
 */

/* Test if run on RV32 */
#if (__riscv_xlen != 32)
#error Only for RV32. Cannot continue.
#else

/* Set to 0 to skip some system calls. There
 * are some system calls that just return an
 * error because they cannot fulfill the
 * desired action */
#ifndef FULL_SYSTEM_CALLS
#define FULL_SYSTEM_CALLS (1)
#endif

#include <stdint.h>
#include <errno.h>
#include <machine/syscall.h>
#include <sys/time.h>
#include <sys/stat.h>
#include <stdlib.h>

#include "handlers_vectored.h"

/* We use naked instead of interrupt because interrupt
 * will create a stack frame and restores a0, but that
 * register has to be used as return code for system
 * calls, hence naked. This means that we have to save
 * and restore registers ourselves and supply the MRET
 * instruction. */
void __attribute__ ((naked)) universal_handler(void);

/* End of the data, start of the free RAM */
extern char *_end;
/* Symbols for stack pointer and stack size from linker */
extern char __stack_pointer$;
extern char __stack_size;

/* Empty environment */
char *__env[1] = { 0 };
char **environ = __env;

/* Exceptions */
#define INSTRUCTION_ALIGNED_FAULT_IN_MCAUSE (0)
#define INSTRUCTION_ACCESS_FAULT_IN_MCAUSE (1)
#define ILLEGAL_INSTRUCTION_IN_MCAUSE (2)
#define EBREAK_IN_MCAUSE (3)
#define LOAD_ALIGNED_FAULT_IN_MCAUSE (4)
#define LOAD_ACCESS_FAULT_IN_MCAUSE (5)
#define STORE_ALIGNED_FAULT_IN_MCAUSE (6)
#define STORE_ACCESS_FAULT_IN_MCAUSE (7)
#define ECALL_IN_MCAUSE (11)

/* User callable functions for writing and reading
 * to files. Normally these functions are used to
 * access the onboard USART.
 * NOTE: THESE FUNCTIONS MUST NOT USE ECALL OR
 * EBREAK OR CAUSE ANY EXCEPTIONS/TRAPS */
__attribute__((weak)) int __io_putchar(int ch) {
	return 0;
}

__attribute__((weak)) int __io_getchar(void) {
	return 0;
}

/* For vectored mode, use this jump table to
 * enter the specific interrupt handler OR
 * use the default, universal exception
 * handler. DON'T CALL THIS FUNCTION. */
__attribute__ ((naked))
void handler_jump_table(void)
{
	/* Handlers for RISC-V interrupts. Only Machine
	 * Timer Interrupt is available. */
	__asm__ volatile ("j universal_handler;");
	__asm__ volatile ("j default_handler;");
	__asm__ volatile ("j default_handler;");
	__asm__ volatile ("j default_handler;");
	__asm__ volatile ("j default_handler;");
	__asm__ volatile ("j default_handler;");
	__asm__ volatile ("j default_handler;");
	__asm__ volatile ("j external_timer_handler;");
	__asm__ volatile ("j default_handler;");
	__asm__ volatile ("j default_handler;");
	__asm__ volatile ("j default_handler;");
	__asm__ volatile ("j default_handler;");
	__asm__ volatile ("j default_handler;");
	__asm__ volatile ("j default_handler;");
	__asm__ volatile ("j default_handler;");
	__asm__ volatile ("j default_handler;");

	/* Next are the core local interrupts (16 max) */
	__asm__ volatile ("j external_input_handler;");
	__asm__ volatile ("j timer1_handler;");
	__asm__ volatile ("j uart1_handler;");
	__asm__ volatile ("j timer2_handler;");
	__asm__ volatile ("j i2c1_handler;");
	__asm__ volatile ("j spi1_handler;");
	__asm__ volatile ("j default_handler;");
	__asm__ volatile ("j default_handler;");
	__asm__ volatile ("j default_handler;");
	__asm__ volatile ("j default_handler;");
	__asm__ volatile ("j default_handler;");
	__asm__ volatile ("j default_handler;");
	__asm__ volatile ("j default_handler;");
	__asm__ volatile ("j default_handler;");
	__asm__ volatile ("j default_handler;");
	__asm__ volatile ("j default_handler;");
}

/* This is the universal handler. We use a lot of register
 * qualifiers in the hope that the compiler will catch
 * the hint ;-) */
__attribute__ ((naked))
void universal_handler(void)
{
	/* Save registers. We need to save all the registers
	 * including a0 (x10) but note that system calls
	 * return the status code in a0, so in that case
	 * we must not restore a0. We also save MCAUSE,
     * MEPC, the faulting instruction and MTVAL. */
	__asm__ volatile ("addi    sp,sp,-36*4;"
		          "sw      x1,1*4(sp);"
		          "sw      x2,2*4(sp);"
		          "sw      x3,3*4(sp);"
		          "sw      x4,4*4(sp);"
		          "sw      x5,5*4(sp);"
		          "sw      x6,6*4(sp);"
		          "sw      x7,7*4(sp);"
		          "sw      x8,8*4(sp);"
		          "sw      x9,9*4(sp);"
		          "sw      x10,10*4(sp);"
		          "sw      x11,11*4(sp);"
		          "sw      x12,12*4(sp);"
		          "sw      x13,13*4(sp);"
		          "sw      x14,14*4(sp);"
		          "sw      x15,15*4(sp);"
		          "sw      x16,16*4(sp);"
		          "sw      x17,17*4(sp);"
		          "sw      x18,18*4(sp);"
		          "sw      x19,19*4(sp);"
		          "sw      x20,20*4(sp);"
		          "sw      x21,21*4(sp);"
		          "sw      x22,22*4(sp);"
		          "sw      x23,23*4(sp);"
		          "sw      x24,24*4(sp);"
		          "sw      x25,25*4(sp);"
		          "sw      x26,26*4(sp);"
		          "sw      x27,27*4(sp);"
		          "sw      x28,28*4(sp);"
		          "sw      x29,29*4(sp);"
		          "sw      x30,30*4(sp);"
		          "sw      x31,31*4(sp);"
		          "csrr    t0,mcause;"
				  "sw      t0,32*4(sp);"
				  "csrr    t0,mepc;"
				  "sw      t0,33*4(sp);"
				  "lw      t0,0(t0);"
				  "sw      t0,34*4(sp);"
				  "csrr    t0,mtval;"
				  "sw      t0,35*4(sp);"
	      	          :::);

	/* mcause from CSR */
 	register uint32_t __mcause;

	/* System call ID in a7 */
	register int32_t syscall_id __asm__("a7");
	/* Return value in a0, must be done using __asm__ */
	register int32_t return_value = 0;
	/* The stack pointer on entering this function */
	register uint32_t stack_pointer __asm__("sp");

	/* Read in the mcause CSR */
	__asm__ volatile ("csrr %0, mcause;"
		          : "=r" (__mcause) :
 		          : "memory");

	/* Only synchronous traps enter here */
	/* Check the cause of the exeption/trap */
	if (__mcause == ECALL_IN_MCAUSE) {
		/* ECALL used, so system call. Most likely
		 * system calls are first. The exit system
		 * call is only called at the end so is last.
		 * Not-so-many-used or not-implemented system
		 * calls are at the very end and may be omitted
		 * by setting the preprocessor macro
		 * FULL_SYSTEM_CALLS to 0. */

		/* brk system call. When called with 0 bytes,
		 * this call returns the base address of the
		 * heap, otherwise the end heap address is
		 * calculated and tested against the end of
		 * the allocated stack space. */
		if (syscall_id == SYS_brk) {
			/* For retrieving of the initial sp and stack size */
			register uint32_t a0 __asm__("a0");
			register uint32_t sp_val, ss_val;
			sp_val = (uint32_t) &__stack_pointer$;
			ss_val = (uint32_t) &__stack_size;
			/* Check for 0, used to initialise the system */
			if (a0 == 0) {
				return_value = (uint32_t) &_end;
			/* Check if new end address of buffer is greater
			 * than the top lowest stack address allocated
			 * to avoid stack clash. */
			} else if (a0 < sp_val - ss_val) {
				return_value = a0;
			} else {
				errno = ENOMEM;
				return_value = -1;
			}
			__asm__ volatile ("mv a0,%0" : : "r"(return_value));
		/* read system call. Currently calls __io_getchar
		 * but that takes a lot of time if the input is
		 * from a USART. */
		} else if (syscall_id == SYS_read) {
			register uint32_t a1 __asm__("a1");
			register uint32_t a2 __asm__("a2");
			register char *buf = (char *) a1;
			register int len = (int) a2;
			register int i;
			for (i = 0; i < len; i++) {
				*buf++ = __io_getchar();
			}
			return_value = len;
			__asm__ volatile ("mv a0,%0" : : "r"(return_value));
		/* write system call. Currently calls __io_putchar
		 * but that takes a lot of time if the output is
		 * to a USART. */
		} else if (syscall_id == SYS_write) {
			register uint32_t a1 __asm__("a1");
			register uint32_t a2 __asm__("a2");
			register char *buf = (char *) a1;
			register int len = (int) a2;
			register int i;
			for (i = 0; i < len; i++) {
				__io_putchar(*buf++);
			}
			return_value = len;
			__asm__ volatile ("mv a0,%0" : : "r"(return_value));
		/* gettimeofday system call */
		/* takes a lot of time because of the divisions */
		} else if (syscall_id == SYS_gettimeofday) {
			register uint32_t a0 __asm__("a0");
			register struct timeval *ptv = (struct timeval *) a0;
			register uint64_t thetime;
			register uint32_t th,tl,tt;
			th = tl = tt = 0;

			/* Read in the 64-bit, micro second accurate
			 * time CSRs, which are a copy of TIME and TIMEH
			 * memory mapped registers */
			__asm__ volatile("1: rdtimeh %0\n"
		         	     "   rdtime  %1\n"
			 	     "   rdtimeh %2\n"
				     "   bne %0, %2, 1b"
				     : "+r" (th), "+r" (tl), "+r" (tt));

			thetime = ((uint64_t)th << 32ULL) | (uint64_t) tl;
			/* This division and remainder take a long time */
			ptv->tv_usec = (uint32_t) (thetime % 1000000ULL);
			ptv->tv_sec = (uint64_t) (thetime / 1000000ULL);
			return_value = 0;
			__asm__ volatile ("mv a0,%0" : : "r"(return_value));
		/* exit system call */
		} else if (syscall_id == SYS_exit) {
			return_value = 0;
			__asm__ volatile ("mv a0,%0" : : "r"(return_value));
#if FULL_SYSTEM_CALLS == 1
		/* open system call */
		} else if (syscall_id == SYS_open) {
			errno = EBADF;
			return_value = -1;
			__asm__ volatile ("mv a0,%0" : : "r"(return_value));
		/* close system call */
		} else if (syscall_id == SYS_close) {
			errno = EBADF;
			return_value = -1;
			__asm__ volatile ("mv a0,%0" : : "r"(return_value));
		/* fstat system call */
		} else if (syscall_id == SYS_fstat) {
			register uint32_t a1 __asm__("a1");
			register struct stat *pst = (struct stat *) a1;
			pst->st_mode = S_IFCHR;
			return_value = 0;
			__asm__ volatile ("mv a0,%0" : : "r"(return_value));
		/* stat system call */
		} else if (syscall_id == SYS_stat) {
			register uint32_t a1 __asm__("a1");
			register struct stat *pst = (struct stat *) a1;
			pst->st_mode = S_IFCHR;
			return_value = 0;
			__asm__ volatile ("mv a0,%0" : : "r"(return_value));
		/* fstatat system call */
		} else if (syscall_id == SYS_fstatat) {
			register uint32_t a1 __asm__("a1");
			register struct stat *pst = (struct stat *) a1;
			pst->st_mode = S_IFCHR;
			return_value = 0;
			__asm__ volatile ("mv a0,%0" : : "r"(return_value));
		/* lstat system call */
		} else if (syscall_id == SYS_lstat) {
			register uint32_t a1 __asm__("a1");
			register struct stat *pst = (struct stat *) a1;
			pst->st_mode = S_IFCHR;
			return_value = 0;
			__asm__ volatile ("mv a0,%0" : : "r"(return_value));
		/* unlink system call */
		} else if (syscall_id == SYS_unlink) {
			errno = ENOENT;
			return_value = -1;
			__asm__ volatile ("mv a0,%0" : : "r"(return_value));
		/* lseek system call */
		} else if (syscall_id == SYS_lseek) {
			return_value = 0;
			__asm__ volatile ("mv a0,%0" : : "r"(return_value));
		/* link system call */
		} else if (syscall_id == SYS_link) {
			errno = EMLINK;
			return_value = -1;
			__asm__ volatile ("mv a0,%0" : : "r"(return_value));
		/* access system call */
		} else if (syscall_id == SYS_access) {
			errno = EACCES;
			return_value = -1;
			__asm__ volatile ("mv a0,%0" : : "r"(return_value));
#endif
		/* Unimplemented/unavailable system calls */
		} else {
			errno = ENOSYS;
			return_value = -1;
			__asm__ volatile ("mv a0,%0" : : "r"(return_value));
		}
	} else if (__mcause == EBREAK_IN_MCAUSE) {
		/* Calls the debugger. Currently a stub. */
		debugger((trap_frame_t *)stack_pointer);
		__asm__ volatile ("lw      x10,10*4(sp);" :::);
	} else if (__mcause == ILLEGAL_INSTRUCTION_IN_MCAUSE) {
		/* Do nothing for now. Must handle illegal instruction.
		 * Currently only restores a0. */
		__asm__ volatile ("lw      x10,10*4(sp);" :::);
	} else if (__mcause == LOAD_ACCESS_FAULT_IN_MCAUSE) {
		/* Loading of unimplemented memory.
		 * Currently only restores a0. */
		__asm__ volatile ("lw      x10,10*4(sp);" :::);
	} else if (__mcause == STORE_ACCESS_FAULT_IN_MCAUSE) {
		/* Storing of unimplemented memory.
		 * Currently only restores a0. */
		__asm__ volatile ("lw      x10,10*4(sp);" :::);
	} else {
		/* Not supported or unknown. Currenlty only
		 * restores a0. */
		__asm__ volatile ("lw      x10,10*4(sp);" :::);
	}

	/* Fetch registers. We need to reload all the registers
	 * with the exception of a0 (x10) because it is used
	 * as return value from the system calls or reads in a0
	 * in the indicated regions. If the trap was due to an
	 * exception, then add 4 to MEPC. Returns with MRET
	 * instruction */
	__asm__ volatile (
                    "lw      t0,32*4(sp);" /* Load mcause */
                    "blt     t0,zero,1f;"  /* Is interrupt? */
                    "csrr    t0,mepc;"     /* Then skip */
                    "addi    t0,t0,4;"     /* Exception: increment MEPC by 4 */
                    "csrw    mepc,t0;"     /* Write MEPC */
                    "1:;"
					"lw      x31,31*4(sp);"
					"lw      x30,30*4(sp);"
					"lw      x29,29*4(sp);"
					"lw      x28,28*4(sp);"
					"lw      x27,27*4(sp);"
					"lw      x26,26*4(sp);"
					"lw      x25,25*4(sp);"
					"lw      x24,24*4(sp);"
					"lw      x23,23*4(sp);"
					"lw      x22,22*4(sp);"
					"lw      x21,21*4(sp);"
					"lw      x20,20*4(sp);"
					"lw      x19,19*4(sp);"
					"lw      x18,18*4(sp);"
					"lw      x17,17*4(sp);"
					"lw      x16,16*4(sp);"
					"lw      x15,15*4(sp);"
					"lw      x14,14*4(sp);"
					"lw      x13,13*4(sp);"
					"lw      x12,12*4(sp);"
					"lw      x11,11*4(sp);"
					"lw      x9,9*4(sp);"
					"lw      x8,8*4(sp);"
					"lw      x7,7*4(sp);"
					"lw      x6,6*4(sp);"
					"lw      x5,5*4(sp);"
					"lw      x4,4*4(sp);"
					"lw      x3,3*4(sp);"
					"lw      x2,2*4(sp);"
					"lw      x1,1*4(sp);"
					"addi    sp,sp,36*4;"
					"mret"
	      	          :::);
}

#endif

