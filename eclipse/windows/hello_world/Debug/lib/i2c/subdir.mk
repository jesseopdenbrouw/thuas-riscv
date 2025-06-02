################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../lib/i2c/i2c1_init.c \
../lib/i2c/i2c1_receive.c \
../lib/i2c/i2c1_receive_byte.c \
../lib/i2c/i2c1_transmit.c \
../lib/i2c/i2c1_transmit_address.c \
../lib/i2c/i2c1_transmit_address_only.c \
../lib/i2c/i2c1_transmit_byte.c \
../lib/i2c/i2c2_init.c \
../lib/i2c/i2c2_receive.c \
../lib/i2c/i2c2_receive_byte.c \
../lib/i2c/i2c2_transmit.c \
../lib/i2c/i2c2_transmit_address.c \
../lib/i2c/i2c2_transmit_address_only.c \
../lib/i2c/i2c2_transmit_byte.c 

OBJS += \
./lib/i2c/i2c1_init.o \
./lib/i2c/i2c1_receive.o \
./lib/i2c/i2c1_receive_byte.o \
./lib/i2c/i2c1_transmit.o \
./lib/i2c/i2c1_transmit_address.o \
./lib/i2c/i2c1_transmit_address_only.o \
./lib/i2c/i2c1_transmit_byte.o \
./lib/i2c/i2c2_init.o \
./lib/i2c/i2c2_receive.o \
./lib/i2c/i2c2_receive_byte.o \
./lib/i2c/i2c2_transmit.o \
./lib/i2c/i2c2_transmit_address.o \
./lib/i2c/i2c2_transmit_address_only.o \
./lib/i2c/i2c2_transmit_byte.o 

C_DEPS += \
./lib/i2c/i2c1_init.d \
./lib/i2c/i2c1_receive.d \
./lib/i2c/i2c1_receive_byte.d \
./lib/i2c/i2c1_transmit.d \
./lib/i2c/i2c1_transmit_address.d \
./lib/i2c/i2c1_transmit_address_only.d \
./lib/i2c/i2c1_transmit_byte.d \
./lib/i2c/i2c2_init.d \
./lib/i2c/i2c2_receive.d \
./lib/i2c/i2c2_receive_byte.d \
./lib/i2c/i2c2_transmit.d \
./lib/i2c/i2c2_transmit_address.d \
./lib/i2c/i2c2_transmit_address_only.d \
./lib/i2c/i2c2_transmit_byte.d 


# Each subdirectory must supply rules for building sources it contributes
lib/i2c/%.o: ../lib/i2c/%.c lib/i2c/subdir.mk
	@echo 'Building file: $<'
	@echo 'Invoking: GNU RISC-V Cross C Compiler'
	riscv-none-elf-gcc.cmd -march=rv32im_zicsr -mabi=ilp32 -msmall-data-limit=8 -mno-save-restore -O0 -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections -g3 -isystem"D:\PROJECTS\RISCVDEV\thuas-riscv\eclipse\windows\hello_world\include" -std=gnu11 -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


