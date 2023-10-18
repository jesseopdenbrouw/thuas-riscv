#  Common settings for the programs

# Compiler defaults
CC = riscv32-unknown-elf-gcc
CXX = riscv32-unknown-elf-g++
OBJCOPY = riscv32-unknown-elf-objcopy
AR = riscv32-unknown-elf-ar
SIZE = riscv32-unknown-elf-size
SREC2VHDL = ../bin/srec2vhdl
UPLOAD = ../bin/upload

# The clock frequency of the system
ifndef F_CPU
F_CPU = "(50000000UL)"
endif

# The default baud rate of the USART
ifndef BAUD_RATE
BAUD_RATE = "(115200UL)"
endif

# Set to program name in Makefile
ifndef PROG_NAME
PROG_NAME = \"mad_cow\"
endif

# Set to the startup file
CRT_PATH = ../crt
CRT = startup.c

# Needed for binutils >= 2.39, set to empty otherwise
EXTRA_LINKER_FLAGS=-Wl,--no-warn-rwx-segments

# Linker script
LD_SCRIPT = ../ldfiles/riscv.ld

# Include dir
INCPATH = ../include

# THUAS RISCV library and set search path
#LIBTHUASRV32STRING = -lthuasrv32 -L../lib
# The library libthuasrv32.a is loaded with thuas.specs file
LIBTHUASRV32STRING = -L../lib

# Architecture and ABI
# KEEP THIS FOR NOW
MARCHABISTRING = -march=rv32im_zicsr -mabi=ilp32
#MARCHABISTRING = -march=rv32im_zicsr_zba -mabi=ilp32

# Linker specs files
SPECSSTRING = --specs=../lib/thuas.specs --specs=../lib/nano.specs

# options for the UPLOAD program
UPLOAD_OPTIONS= -nv -d /dev/ttyUSB0
