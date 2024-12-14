################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../lib/wdt/wdt_init.c \
../lib/wdt/wdt_reset.c \
../lib/wdt/wdt_start.c \
../lib/wdt/wdt_stop.c 

OBJS += \
./lib/wdt/wdt_init.o \
./lib/wdt/wdt_reset.o \
./lib/wdt/wdt_start.o \
./lib/wdt/wdt_stop.o 

C_DEPS += \
./lib/wdt/wdt_init.d \
./lib/wdt/wdt_reset.d \
./lib/wdt/wdt_start.d \
./lib/wdt/wdt_stop.d 


# Each subdirectory must supply rules for building sources it contributes
lib/wdt/%.o: ../lib/wdt/%.c lib/wdt/subdir.mk
	@echo 'Building file: $<'
	@echo 'Invoking: GNU RISC-V Cross C Compiler'
	riscv-none-elf-gcc.cmd -march=rv32im_zicsr -mabi=ilp32 -msmall-data-limit=8 -mno-save-restore -O3 -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections -g3 -isystem"D:\PROJECTS\RISCVDEV\thuas-riscv-with-new-io\eclipse\windows\coremark\include" -std=gnu11 -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


