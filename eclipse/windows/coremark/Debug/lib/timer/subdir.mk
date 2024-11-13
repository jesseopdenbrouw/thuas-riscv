################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../lib/timer/timer1_clear_interrupt.c \
../lib/timer/timer1_disable.c \
../lib/timer/timer1_disable_interrupt.c \
../lib/timer/timer1_enable.c \
../lib/timer/timer1_enable_interrupt.c \
../lib/timer/timer1_getcounter.c \
../lib/timer/timer1_setcompare.c \
../lib/timer/timer1_setcounter.c 

O_SRCS += \
../lib/timer/timer1_clear_interrupt.o \
../lib/timer/timer1_disable.o \
../lib/timer/timer1_disable_interrupt.o \
../lib/timer/timer1_enable.o \
../lib/timer/timer1_enable_interrupt.o \
../lib/timer/timer1_getcounter.o \
../lib/timer/timer1_setcompare.o \
../lib/timer/timer1_setcounter.o 

OBJS += \
./lib/timer/timer1_clear_interrupt.o \
./lib/timer/timer1_disable.o \
./lib/timer/timer1_disable_interrupt.o \
./lib/timer/timer1_enable.o \
./lib/timer/timer1_enable_interrupt.o \
./lib/timer/timer1_getcounter.o \
./lib/timer/timer1_setcompare.o \
./lib/timer/timer1_setcounter.o 

C_DEPS += \
./lib/timer/timer1_clear_interrupt.d \
./lib/timer/timer1_disable.d \
./lib/timer/timer1_disable_interrupt.d \
./lib/timer/timer1_enable.d \
./lib/timer/timer1_enable_interrupt.d \
./lib/timer/timer1_getcounter.d \
./lib/timer/timer1_setcompare.d \
./lib/timer/timer1_setcounter.d 


# Each subdirectory must supply rules for building sources it contributes
lib/timer/%.o: ../lib/timer/%.c lib/timer/subdir.mk
	@echo 'Building file: $<'
	@echo 'Invoking: GNU RISC-V Cross C Compiler'
	riscv-none-elf-gcc.cmd -march=rv32im_zicsr -mabi=ilp32 -msmall-data-limit=8 -mno-save-restore -O3 -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections -g3 -isystem"D:\PROJECTS\RISCVDEV\thuas-riscv\eclipse\windows\coremark\include" -std=gnu11 -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


