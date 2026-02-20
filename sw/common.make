#  Common settings for the programs


ifeq ($(OS),Windows_NT)
# For xPack RISC-V compiler
PREFIX = riscv-none-elf
else
# For Linux
PREFIX = riscv32-unknown-elf
endif

# Compiler defaults
CC = $(PREFIX)-gcc
CXX = $(PREFIX)-g++
OBJCOPY = $(PREFIX)-objcopy
AR = $(PREFIX)-ar
SIZE = $(PREFIX)-size
SREC2VHDL = ../bin/srec2vhdl
UPLOAD = ../bin/upload
OPENOCD = openocd

# Common settings of flags
CFLAGS = -g -O2 -Wall -DF_CPU=$(F_CPU) -DBAUD_RATE=$(BAUD_RATE) -DPROG_NAME=$(PROG_NAME) -I$(INCPATH) $(MARCHABISTRING)
LDFLAGS = -g -lm -Wall -nostartfiles -T $(LD_SCRIPT) $(LIBTHUASRV32STRING) $(MARCHABISTRING) $(SPECSSTRING) $(MORE_LINKER_FLAGS) -Wl,--gc-sections

# The clock frequency of the system
ifndef F_CPU
F_CPU = "(50000000UL)"
endif

# The default baud rate of the UART
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
MORE_LINKER_FLAGS=-Wl,--no-warn-rwx-segments

# Linker script
LD_SCRIPT = ../ldfiles/riscv.ld

# Include dir
INCPATH = ../include

# The library libthuasrv32.a is loaded with thuas.specs file
LIBTHUASRV32STRING = -L../lib

# Architecture and ABI
MARCHABISTRING = -march=rv32im_zicsr -mabi=ilp32
# With B extension and Zicond
#MARCHABISTRING = -march=rv32im_zicsr_zimop_zba_zbb_zbs_zicond -mabi=ilp32

# Linker specs files
SPECSSTRING = --specs=../lib/thuas.specs --specs=../lib/nano.specs
#SPECSSTRING = --specs=../lib/thuas.specs --specs=nano.specs

# Options for the UPLOAD program
ifeq ($(OS),Windows_NT)
UPLOAD_OPTIONS= -nv -d COM1
else
UPLOAD_OPTIONS= -nv -d /dev/ttyUSB0
endif

# OpenOCD config file from software examples
OPENOCDCFG = "../../openocd/openocd.cfg"
