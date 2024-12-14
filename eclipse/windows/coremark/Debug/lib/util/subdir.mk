################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../lib/util/delayms.c \
../lib/util/gethex.c \
../lib/util/parsehex.c \
../lib/util/printdec.c \
../lib/util/printhex.c \
../lib/util/printhwversion.c \
../lib/util/printlogo.c 

OBJS += \
./lib/util/delayms.o \
./lib/util/gethex.o \
./lib/util/parsehex.o \
./lib/util/printdec.o \
./lib/util/printhex.o \
./lib/util/printhwversion.o \
./lib/util/printlogo.o 

C_DEPS += \
./lib/util/delayms.d \
./lib/util/gethex.d \
./lib/util/parsehex.d \
./lib/util/printdec.d \
./lib/util/printhex.d \
./lib/util/printhwversion.d \
./lib/util/printlogo.d 


# Each subdirectory must supply rules for building sources it contributes
lib/util/%.o: ../lib/util/%.c lib/util/subdir.mk
	@echo 'Building file: $<'
	@echo 'Invoking: GNU RISC-V Cross C Compiler'
	riscv-none-elf-gcc.cmd -march=rv32im_zicsr -mabi=ilp32 -msmall-data-limit=8 -mno-save-restore -O3 -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections -g3 -isystem"D:\PROJECTS\RISCVDEV\thuas-riscv-with-new-io\eclipse\windows\coremark\include" -std=gnu11 -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


