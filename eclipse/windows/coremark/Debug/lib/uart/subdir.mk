################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../lib/uart/uart1_getc.c \
../lib/uart/uart1_gets.c \
../lib/uart/uart1_init.c \
../lib/uart/uart1_printf.c \
../lib/uart/uart1_printlonglong.c \
../lib/uart/uart1_printulonglong.c \
../lib/uart/uart1_putc.c \
../lib/uart/uart1_puts.c \
../lib/uart/uart_hasreceived.c 

OBJS += \
./lib/uart/uart1_getc.o \
./lib/uart/uart1_gets.o \
./lib/uart/uart1_init.o \
./lib/uart/uart1_printf.o \
./lib/uart/uart1_printlonglong.o \
./lib/uart/uart1_printulonglong.o \
./lib/uart/uart1_putc.o \
./lib/uart/uart1_puts.o \
./lib/uart/uart_hasreceived.o 

C_DEPS += \
./lib/uart/uart1_getc.d \
./lib/uart/uart1_gets.d \
./lib/uart/uart1_init.d \
./lib/uart/uart1_printf.d \
./lib/uart/uart1_printlonglong.d \
./lib/uart/uart1_printulonglong.d \
./lib/uart/uart1_putc.d \
./lib/uart/uart1_puts.d \
./lib/uart/uart_hasreceived.d 


# Each subdirectory must supply rules for building sources it contributes
lib/uart/%.o: ../lib/uart/%.c lib/uart/subdir.mk
	@echo 'Building file: $<'
	@echo 'Invoking: GNU RISC-V Cross C Compiler'
	riscv-none-elf-gcc.cmd -march=rv32im_zicsr -mabi=ilp32 -msmall-data-limit=8 -mno-save-restore -O3 -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections -g3 -isystem"D:\PROJECTS\RISCVDEV\thuas-riscv-with-new-io\eclipse\windows\coremark\include" -std=gnu11 -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


