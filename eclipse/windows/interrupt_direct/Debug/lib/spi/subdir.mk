################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../lib/spi/spi1_csdisable.c \
../lib/spi/spi1_csenable.c \
../lib/spi/spi1_init.c \
../lib/spi/spi1_receive.c \
../lib/spi/spi1_transfer.c \
../lib/spi/spi1_transmit.c \
../lib/spi/spi1_transmit_receive.c \
../lib/spi/spi2_csdisable.c \
../lib/spi/spi2_csenable.c \
../lib/spi/spi2_init.c \
../lib/spi/spi2_transfer.c 

O_SRCS += \
../lib/spi/spi1_csdisable.o \
../lib/spi/spi1_csenable.o \
../lib/spi/spi1_init.o \
../lib/spi/spi1_receive.o \
../lib/spi/spi1_transfer.o \
../lib/spi/spi1_transmit.o \
../lib/spi/spi1_transmit_receive.o \
../lib/spi/spi2_csdisable.o \
../lib/spi/spi2_csenable.o \
../lib/spi/spi2_init.o \
../lib/spi/spi2_transfer.o 

OBJS += \
./lib/spi/spi1_csdisable.o \
./lib/spi/spi1_csenable.o \
./lib/spi/spi1_init.o \
./lib/spi/spi1_receive.o \
./lib/spi/spi1_transfer.o \
./lib/spi/spi1_transmit.o \
./lib/spi/spi1_transmit_receive.o \
./lib/spi/spi2_csdisable.o \
./lib/spi/spi2_csenable.o \
./lib/spi/spi2_init.o \
./lib/spi/spi2_transfer.o 

C_DEPS += \
./lib/spi/spi1_csdisable.d \
./lib/spi/spi1_csenable.d \
./lib/spi/spi1_init.d \
./lib/spi/spi1_receive.d \
./lib/spi/spi1_transfer.d \
./lib/spi/spi1_transmit.d \
./lib/spi/spi1_transmit_receive.d \
./lib/spi/spi2_csdisable.d \
./lib/spi/spi2_csenable.d \
./lib/spi/spi2_init.d \
./lib/spi/spi2_transfer.d 


# Each subdirectory must supply rules for building sources it contributes
lib/spi/%.o: ../lib/spi/%.c lib/spi/subdir.mk
	@echo 'Building file: $<'
	@echo 'Invoking: GNU RISC-V Cross C Compiler'
	riscv-none-elf-gcc.cmd -march=rv32im_zicsr -mabi=ilp32 -msmall-data-limit=8 -mno-save-restore -O0 -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections -g3 -isystem"D:\PROJECTS\RISCVDEV\thuas-riscv-with-new-io\eclipse\windows\interrupt_direct\include" -std=gnu11 -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


