/*
 * asm.h -- assembler functions for the THUAS RISCV processor
 *
 */
#ifndef _ASM_H_
#define _ASM_H_

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define nop() asm volatile ("nop\n" :::)

#define ebreak() asm volatile ("ebreak\n" :::)

#define ecall() asm volatile ("ecall\n" :::)

#define wfi() asm volatile ("wfi\n" :::)




#ifdef __cplusplus
}
#endif

#endif
