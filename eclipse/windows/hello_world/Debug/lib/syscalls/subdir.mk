################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../lib/syscalls/sys_env.c \
../lib/syscalls/sys_exit.c \
../lib/syscalls/sys_gettimeofday.c \
../lib/syscalls/sys_read_write.c \
../lib/syscalls/sys_remaining.c \
../lib/syscalls/sys_sbrk.c \
../lib/syscalls/sys_times.c 

O_SRCS += \
../lib/syscalls/sys_env.o \
../lib/syscalls/sys_exit.o \
../lib/syscalls/sys_gettimeofday.o \
../lib/syscalls/sys_read_write.o \
../lib/syscalls/sys_remaining.o \
../lib/syscalls/sys_sbrk.o \
../lib/syscalls/sys_times.o 

OBJS += \
./lib/syscalls/sys_env.o \
./lib/syscalls/sys_exit.o \
./lib/syscalls/sys_gettimeofday.o \
./lib/syscalls/sys_read_write.o \
./lib/syscalls/sys_remaining.o \
./lib/syscalls/sys_sbrk.o \
./lib/syscalls/sys_times.o 

C_DEPS += \
./lib/syscalls/sys_env.d \
./lib/syscalls/sys_exit.d \
./lib/syscalls/sys_gettimeofday.d \
./lib/syscalls/sys_read_write.d \
./lib/syscalls/sys_remaining.d \
./lib/syscalls/sys_sbrk.d \
./lib/syscalls/sys_times.d 


# Each subdirectory must supply rules for building sources it contributes
lib/syscalls/%.o: ../lib/syscalls/%.c lib/syscalls/subdir.mk
	@echo 'Building file: $<'
	@echo 'Invoking: GNU RISC-V Cross C Compiler'
	riscv-none-elf-gcc.cmd -march=rv32im_zicsr -mabi=ilp32 -msmall-data-limit=8 -mno-save-restore -O0 -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections -g3 -isystem"D:\PROJECTS\RISCVDEV\thuas-riscv\eclipse\windows\hello_world\include" -std=gnu11 -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


