################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../lib/csr/csr_get_cycle.c \
../lib/csr/csr_get_instret.c \
../lib/csr/csr_get_mhpmcounter3.c \
../lib/csr/csr_get_mhpmcounter4.c \
../lib/csr/csr_get_mhpmcounter5.c \
../lib/csr/csr_get_mhpmcounter6.c \
../lib/csr/csr_get_mhpmcounter7.c \
../lib/csr/csr_get_mhpmcounter8.c \
../lib/csr/csr_get_mhpmcounter9.c \
../lib/csr/csr_get_time.c 

O_SRCS += \
../lib/csr/csr_get_cycle.o \
../lib/csr/csr_get_instret.o \
../lib/csr/csr_get_mhpmcounter3.o \
../lib/csr/csr_get_mhpmcounter4.o \
../lib/csr/csr_get_mhpmcounter5.o \
../lib/csr/csr_get_mhpmcounter6.o \
../lib/csr/csr_get_mhpmcounter7.o \
../lib/csr/csr_get_mhpmcounter8.o \
../lib/csr/csr_get_mhpmcounter9.o \
../lib/csr/csr_get_time.o 

OBJS += \
./lib/csr/csr_get_cycle.o \
./lib/csr/csr_get_instret.o \
./lib/csr/csr_get_mhpmcounter3.o \
./lib/csr/csr_get_mhpmcounter4.o \
./lib/csr/csr_get_mhpmcounter5.o \
./lib/csr/csr_get_mhpmcounter6.o \
./lib/csr/csr_get_mhpmcounter7.o \
./lib/csr/csr_get_mhpmcounter8.o \
./lib/csr/csr_get_mhpmcounter9.o \
./lib/csr/csr_get_time.o 

C_DEPS += \
./lib/csr/csr_get_cycle.d \
./lib/csr/csr_get_instret.d \
./lib/csr/csr_get_mhpmcounter3.d \
./lib/csr/csr_get_mhpmcounter4.d \
./lib/csr/csr_get_mhpmcounter5.d \
./lib/csr/csr_get_mhpmcounter6.d \
./lib/csr/csr_get_mhpmcounter7.d \
./lib/csr/csr_get_mhpmcounter8.d \
./lib/csr/csr_get_mhpmcounter9.d \
./lib/csr/csr_get_time.d 


# Each subdirectory must supply rules for building sources it contributes
lib/csr/%.o: ../lib/csr/%.c lib/csr/subdir.mk
	@echo 'Building file: $<'
	@echo 'Invoking: GNU RISC-V Cross C Compiler'
	riscv-none-elf-gcc.cmd -march=rv32im_zicsr -mabi=ilp32 -msmall-data-limit=8 -mno-save-restore -O0 -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections -g3 -isystem"D:\PROJECTS\RISCVDEV\thuas-riscv-with-new-io\eclipse\windows\hello_world\include" -std=gnu11 -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


