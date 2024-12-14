################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../src/__io_getchar.c \
../src/__io_putchar.c \
../src/handlers_direct.c \
../src/interrupt_direct.c \
../src/trap_handler_direct.c 

OBJS += \
./src/__io_getchar.o \
./src/__io_putchar.o \
./src/handlers_direct.o \
./src/interrupt_direct.o \
./src/trap_handler_direct.o 

C_DEPS += \
./src/__io_getchar.d \
./src/__io_putchar.d \
./src/handlers_direct.d \
./src/interrupt_direct.d \
./src/trap_handler_direct.d 


# Each subdirectory must supply rules for building sources it contributes
src/%.o: ../src/%.c src/subdir.mk
	@echo 'Building file: $<'
	@echo 'Invoking: GNU RISC-V Cross C Compiler'
	riscv-none-elf-gcc.cmd -march=rv32im_zicsr -mabi=ilp32 -msmall-data-limit=8 -mno-save-restore -O0 -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections -g3 -isystem"D:\PROJECTS\RISCVDEV\thuas-riscv-with-new-io\eclipse\windows\interrupt_direct\include" -std=gnu11 -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


