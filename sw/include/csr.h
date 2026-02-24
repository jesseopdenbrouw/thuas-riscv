
/*
 * csr.h -- some common routines for CSR handling
 */


#ifndef _CSR_H
#define _CSR_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Get the number of clock cycles */
uint64_t csr_get_cycle(void);
/* Get the time in micro seconds */
uint64_t csr_get_time(void);
/* Get the number of retired instructions */
uint64_t csr_get_instret(void);
/* Get mhpmcounter3 */
uint64_t csr_get_mhpmcounter3(void);
/* Get mhpmcounter4 */
uint64_t csr_get_mhpmcounter4(void);
/* Get mhpmcounter5 */
uint64_t csr_get_mhpmcounter5(void);
/* Get mhpmcounter6 */
uint64_t csr_get_mhpmcounter6(void);
/* Get mhpmcounter7 */
uint64_t csr_get_mhpmcounter7(void);
/* Get mhpmcounter8 */
uint64_t csr_get_mhpmcounter8(void);
/* Get mhpmcounter9 */
uint64_t csr_get_mhpmcounter9(void);

/* Some macros to read/write CSRs, based on */
/* https://github.com/torvalds/linux/blob/master/arch/riscv/include/asm/csr.h */
#define csr_read(csr)  			     		\
({											\
	register uint32_t __v;					\
	__asm__ __volatile__ ("csrr %0, " #csr	\
						  : "=r" (__v) :	\
						  : "memory");		\
	__v;									\
})

#define csr_write(csr, val)						\
({												\
	uint32_t __v = (uint32_t)(val);				\
	__asm__ __volatile__ ("csrw " #csr ", %0"	\
			      : : "rK" (__v)				\
			      : "memory");					\
})

#define csr_read_set(csr, val)						\
({													\
	uint32_t __v = (uint32_t)(val);					\
	__asm__ __volatile__ ("csrrs %0, " #csr ", %1"	\
			      : "=r" (__v) : "rK" (__v)			\
			      : "memory");						\
	__v;											\
})

#define csr_set(csr, val)						\
({												\
	uint32_t __v = (uint32_t)(val);				\
	__asm__ __volatile__ ("csrs " #csr ", %0"	\
			      : : "rK" (__v)				\
			      : "memory");					\
})

#define csr_read_clear(csr, val)					\
({													\
	uint32_t __v = (uint32_t)(val);					\
	__asm__ __volatile__ ("csrrc %0, " #csr ", %1"	\
			      : "=r" (__v) : "rK" (__v)			\
			      : "memory");						\
	__v;											\
})

#define csr_clear(csr, val)						\
({								                \
	uint32_t __v = (uint32_t)(val);				\
	__asm__ __volatile__ ("csrc " #csr ", %0"	\
			      : : "rK" (__v)				\
			      : "memory");					\
})

#define csr_swap(csr, val)							\
({													\
	uint32_t __v = (uint32_t)(val);					\
	__asm__ __volatile__ ("csrrw %0, " #csr ", %1"	\
			      : "=r" (__v) : "rK" (__v)			\
			      : "memory");						\
	__v;											\
})

/* mxhw CSR */
#define CSR_MXHW_GPIOA     (1 << 0)
#define CSR_MXHW_UART1     (1 << 4)
#define CSR_MXHW_UART2     (1 << 5)
#define CSR_MXHW_I2C1      (1 << 6)
#define CSR_MXHW_I2C2      (1 << 7)
#define CSR_MXHW_SPI1      (1 << 8)
#define CSR_MXHW_SPI2      (1 << 9)
#define CSR_MXHW_TIMER1    (1 << 10)
#define CSR_MXHW_TIMER2    (1 << 11)
#define CSR_MXHW_MULDIV    (1 << 16)
#define CSR_MXHW_FASTDV    (1 << 17)
#define CSR_MXHW_BOOT      (1 << 18)
#define CSR_MXHW_REGRAM    (1 << 19)
#define CSR_MXHW_ZBA       (1 << 20)
#define CSR_MXHW_ZIMOP     (1 << 21)
#define CSR_MXHW_ZICOND    (1 << 22)
#define CSR_MXHW_ZBS       (1 << 23)
#define CSR_MXHW_BREAK     (1 << 24)
#define CSR_MXHW_WDT       (1 << 25)
#define CSR_MXHW_ZIHPM     (1 << 26)
#define CSR_MXHW_OCD       (1 << 27)
#define CSR_MXHW_MSI       (1 << 28)
#define CSR_MXHW_BUFFER    (1 << 29)
#define CSR_MXHW_ZBB       (1 << 30)
#define CSR_MXHW_CRC       (1 << 31)

/* HPM selection bits */
#define CSR_HPM_JUMP       (1 << 0)
#define CSR_HPM_BRANCH     (1 << 0)
#define CSR_HPM_STALLS     (1 << 1)
#define CRR_HPM_STORES     (1 << 2)
#define CSR_HPM_LOADS      (1 << 3)
#define CSR_HPM_ECALLS     (1 << 4)
#define CSR_HPM_EBREAKS    (1 << 5)
#define CSR_HPM_MULDIV     (1 << 6)

#ifdef __cplusplus
}
#endif

#endif
