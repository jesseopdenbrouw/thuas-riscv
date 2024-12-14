################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../lib/gpio/gpioa_readpin.c \
../lib/gpio/gpioa_togglepin.c \
../lib/gpio/gpioa_writepin.c 

OBJS += \
./lib/gpio/gpioa_readpin.o \
./lib/gpio/gpioa_togglepin.o \
./lib/gpio/gpioa_writepin.o 

C_DEPS += \
./lib/gpio/gpioa_readpin.d \
./lib/gpio/gpioa_togglepin.d \
./lib/gpio/gpioa_writepin.d 


# Each subdirectory must supply rules for building sources it contributes
lib/gpio/%.o: ../lib/gpio/%.c lib/gpio/subdir.mk
	@echo 'Building file: $<'
	@echo 'Invoking: GNU RISC-V Cross C Compiler'
	riscv-none-elf-gcc.cmd -march=rv32im_zicsr -mabi=ilp32 -msmall-data-limit=8 -mno-save-restore -O3 -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections -g3 -isystem"D:\PROJECTS\RISCVDEV\thuas-riscv-with-new-io\eclipse\windows\coremark\include" -std=gnu11 -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


