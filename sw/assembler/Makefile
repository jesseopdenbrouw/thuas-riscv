#
# Makefile for assembler programs
#
# This makefile does not link against a CRT file
#

# Compiler defaults
CC = riscv32-unknown-elf-gcc
OBJCOPY = riscv32-unknown-elf-objcopy
AR = riscv32-unknown-elf-ar
SIZE = riscv32-unknown-elf-size
SREC2VHDL = ../bin/srec2vhdl
UPLOAD = ../bin/upload

# The target
TARGET = assembler

#-----
#----- do not edit below this point
#-----

# Program name
PROG_NAME = \"$(TARGET)\"

# Include common defines
COMMON_FILE = ../common.make

# Read in common settings
ifneq ("$(wildcard $(COMMON_FILE))","")
include $(COMMON_FILE)
else
endif

# All header files
HFILES = $(wildcard *.h)

# Find assembler files and transform to object files
SRCS = $(wildcard *.S)
OBJS = $(patsubst %.S, %.o, $(SRCS))

all: $(TARGET).elf

%.o: %.S $(HFILES) $(COMMON_FILE)
	$(CC) $(CFLAGS) -c $< -o $@

$(TARGET).elf: $(OBJS) $(HFILES) $(COMMON_FILE)
	$(CC) -o $(TARGET).elf $(OBJS) $(LDFLAGS)
	$(OBJCOPY) -O srec $(TARGET).elf $(TARGET).srec
	$(SREC2VHDL) -wf $(TARGET).srec $(TARGET).vhd
	$(SIZE) $(TARGET).elf

upload: $(TARGET).srec
	$(UPLOAD) $(UPLOAD_OPTIONS) $(TARGET).srec

clean:
	rm -f $(TARGET).elf $(TARGET).srec $(TARGET).vhd $(OBJS)

