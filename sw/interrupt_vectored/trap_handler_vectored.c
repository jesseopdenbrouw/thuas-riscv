/*
 * RISC-V RV32IM generic trap handler (vectored)
 *
 * (c) 2025, Jesse E.J. op den Brouw
 *
 */

/* Test if run on RV32I */
#if (__riscv_xlen != 32) && !defined(__riscv_32e)
#error Only for RV32I. Cannot continue.
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

/* This struct is needed for gettimeofday system call
 * for RV32I. See newlib/libgloss/riscv/sys_gettimeofday.c
 * In RV32I, gettimeofday C function calls the system
 * call with value SYS_clock_gettime64. See also
 * https://sourceware.org/git/?p=newlib-cygwin.git;a=commitdiff;h=20d00819984058e439cfe40818f81d7315c89201
 */
struct __timespec64
{                 
	int64_t tv_sec;         /* Seconds */
# if BYTE_ORDER == BIG_ENDIAN
	int32_t __padding;      /* Padding */
	int32_t tv_nsec;        /* Nanoseconds */
# else
	int32_t tv_nsec;        /* Nanoseconds */
	int32_t __padding;      /* Padding */
# endif           
};

/* We use naked instead of interrupt because interrupt
 * will create a stack frame and restores a0, but that
 * register has to be used as return code for system
 * calls, hence naked. This means that we have to save
 * and restore registers ourselves and supply the MRET
 * instruction. */
void __attribute__ ((naked, used)) trap_handler_vectored(void);
/* This function does all the work. It is only to be called from the
 * trap_handler_direct function, and it returns to that handler, By
 * ABI, the function is called with parameters stored in the a-
 * registers. The system call number is in a7 */
int32_t __trap_handler_execute(uint32_t _a0, uint32_t _a1, uint32_t _a2, uint32_t _a3,
							   uint32_t _a4, uint32_t _a5, uint32_t _a6, uint32_t syscall_id);

/* End of the data, start of the free RAM */
extern char *_end;
/* Symbols for stack pointer and stack size from linker */
extern char __stack_pointer$;
extern char __stack_size;

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
void trap_handler_jump_table(void)
{
	/* Handlers for RISC-V interrupts. Only Machine
	 * Timer Interrupt is available. */
	__asm__ volatile ("j trap_handler_vectored;");
	__asm__ volatile ("j default_handler;");
	__asm__ volatile ("j default_handler;");
	__asm__ volatile ("j external_msi_handler;");
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
	__asm__ volatile ("j default_handler;");
	__asm__ volatile ("j default_handler;");
	__asm__ volatile ("j external_input_handler;");
	__asm__ volatile ("j default_handler;");
	__asm__ volatile ("j timer1_handler;");
	__asm__ volatile ("j timer2_handler;");
	__asm__ volatile ("j default_handler;");
	__asm__ volatile ("j uart1_handler;");
	__asm__ volatile ("j i2c2_handler;");
	__asm__ volatile ("j default_handler;");
	__asm__ volatile ("j i2c1_handler;");
	__asm__ volatile ("j spi1_handler;");
	__asm__ volatile ("j default_handler;");
	__asm__ volatile ("j default_handler;");
	__asm__ volatile ("j default_handler;");
	__asm__ volatile ("j default_handler;");
}

/* This is the trap handler. It is an all-assembler 
 * function. It saves the registers on stack, calls
 * __trap_handler_execute, and than restores the
 * registers from stack. Please note that system
 * calls are initiated via ECALL and uses a0 for
 * return value. In that case a0 is not restored
 * from the stack */
__attribute__ ((naked, used))
void trap_handler_vectored(void)
{
	/* Save registers. We need to save all the registers
	 * including a0 (x10) but note that system calls
	 * return the status code in a0, so in that case
	 * we must not restore a0. Also save MCAUSE, MEPC,
	 * the faulted instruction and MTVAL. Note that a6
     * is not used in system call argument transfer so
     * we use it for pointing to the trap frame. */
	__asm__ volatile (
					"addi    sp,sp,-36*4;"
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
					"csrr    t0,mcause;"    /* Store mcause */
					"sw      t0,32*4(sp);"
					"csrr    t0,mepc;"      /* Store mepc */
					"sw      t0,33*4(sp);"
					"lw      t0,0(t0);"     /* Store instruction */
					"sw      t0,34*4(sp);"
					"csrr    t0,mtval;"     /* Store mtval */
					"sw      t0,35*4(sp);"
					"mv      a6,sp;"
					"jal     __trap_handler_execute;"   /* Call C-handler */
	      	          :::);
	/* Fetch registers. We need to reload all the registers
	 * but if the trap was due to an ECALL, a0 (x10) must not
     * be loaded, because it is used as return value from
     * system calls. Also increment MEPC with 4 if the trap
	 * was due an exception. Returns with MRET instruction */
	__asm__ volatile (
					"lw      t0,32*4(sp);" /* Load mcause */
					"blt     t0,zero,1f;"  /* Is interrupt? */
					"csrr    t1,mepc;"     /* Then skip */
					"addi    t1,t1,4;"     /* Exception: increment MEPC by 4 */
					"csrw    mepc,t1;"     /* Write MEPC */
					"1:;"
					"li      t1,0x0000000b;" /* ECALL number */
					"beq     t0,t1,2f;"      /* mcause == ECALL? */
					"lw      x10,10*4(sp);"  /* no, load a0 from stack frame */
					"2:;"
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

/* This is this C part of the trap handler. */
int32_t __trap_handler_execute(uint32_t _a0, uint32_t _a1, uint32_t _a2, uint32_t _a3,
							   uint32_t _a4, uint32_t _a5, uint32_t _a6, uint32_t syscall_id) {


	/* mcause from CSR */
 	register uint32_t __mcause;

	/* Return value in a0. */
	register int32_t return_value = 0;

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
			register uint32_t sp_val, ss_val;
			sp_val = (uint32_t) &__stack_pointer$;
			ss_val = (uint32_t) &__stack_size;
			/* Check for 0, used to initialise the system */
			if (_a0 == 0) {
				return_value = (uint32_t) &_end;
			/* Check if new end address of buffer is greater
			 * than the top lowest stack address allocated
			 * to avoid stack clash. */
			} else if (_a0 < sp_val - ss_val) {
				return_value = _a0;
			} else {
				errno = ENOMEM;
				return_value = -1;
			}
		/* read system call. Currently calls __io_getchar
		 * but that takes a lot of time if the input is
		 * from a USART. */
		} else if (syscall_id == SYS_read) {
			register char *buf = (char *) _a1;
			register int len = (int) _a2;
			register int i;
			for (i = 0; i < len; i++) {
				*buf++ = __io_getchar();
			}
			return_value = len;
		/* write system call. Currently calls __io_putchar
		 * but that takes a lot of time if the output is
		 * to a USART. */
		} else if (syscall_id == SYS_write) {
			register char *buf = (char *) _a1;
			register int len = (int) _a2;
			register int i;
			for (i = 0; i < len; i++) {
				__io_putchar(*buf++);
			}
			return_value = len;
		/* gettimeofday system call, for backwards compability, */
		/* RV32I calls system call SYS_clock_gettime64. */
		/* Takes a lot of time because of the divisions */
		} else if (syscall_id == SYS_gettimeofday) {
			register struct timeval *ptv = (struct timeval *) _a0;
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
		/* RV32I gettimeofday calls system call SYS_clock_gettime64 */
		/* See newlib/libgloss/riscv/sys_gettimeofday.c */
		/* Takes a lot of time because of the divisions */
		} else if (syscall_id == SYS_clock_gettime64) {
			register struct __timespec64 *pts64 = (struct __timespec64 *) _a1;
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
			pts64->tv_nsec = (int32_t) ((thetime % 1000000ULL) * 1000ULL);
			pts64->tv_sec = (int64_t) (thetime / 1000000ULL);
			return_value = 0;
		/* exit system call */
		} else if (syscall_id == SYS_exit) {
			return_value = 0;
#if FULL_SYSTEM_CALLS == 1
		/* open system call */
		} else if (syscall_id == SYS_open) {
			errno = EBADF;
			return_value = -1;
		/* close system call */
		} else if (syscall_id == SYS_close) {
			errno = EBADF;
			return_value = -1;
		/* fstat system call */
		} else if (syscall_id == SYS_fstat) {
			register struct stat *pst = (struct stat *) _a1;
			pst->st_mode = S_IFCHR;
			return_value = 0;
		/* stat system call */
		} else if (syscall_id == SYS_stat) {
			register struct stat *pst = (struct stat *) _a1;
			pst->st_mode = S_IFCHR;
			return_value = 0;
		/* fstatat system call */
		} else if (syscall_id == SYS_fstatat) {
			register struct stat *pst = (struct stat *) _a1;
			pst->st_mode = S_IFCHR;
			return_value = 0;
		/* lstat system call */
		} else if (syscall_id == SYS_lstat) {
			register struct stat *pst = (struct stat *) _a1;
			pst->st_mode = S_IFCHR;
			return_value = 0;
		/* unlink system call */
		} else if (syscall_id == SYS_unlink) {
			errno = ENOENT;
			return_value = -1;
		/* lseek system call */
		} else if (syscall_id == SYS_lseek) {
			return_value = 0;
		/* link system call */
		} else if (syscall_id == SYS_link) {
			errno = EMLINK;
			return_value = -1;
		/* access system call */
		} else if (syscall_id == SYS_access) {
			errno = EACCES;
			return_value = -1;
#endif
		/* Unimplemented/unavailable system calls */
		} else {
			errno = ENOSYS;
			return_value = -1;
		}
	} else if (__mcause == EBREAK_IN_MCAUSE) {
		/* Calls the debugger. Currently a stub. */
		debugger((trap_frame_t *) _a6);
	} else if (__mcause == ILLEGAL_INSTRUCTION_IN_MCAUSE) {
		/* Do nothing for now. Must handle illegal instruction. */
	} else if (__mcause == LOAD_ACCESS_FAULT_IN_MCAUSE) {
		/* Loading of unimplemented memory. */
	} else if (__mcause == STORE_ACCESS_FAULT_IN_MCAUSE) {
		/* Storing of unimplemented memory. */
	} else {
		/* Not supported or unknown. */
	}

	return return_value;
}

#endif

