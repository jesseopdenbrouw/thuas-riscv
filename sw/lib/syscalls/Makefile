#
# Makefile for creating the non-trapped system call library
# for the THUAS RISC-V RV32 project.
# See: https://github.com/jesseopdenbrouw/riscv-rv32
#

# Include common defines
COMMON_FILE = ../../common.make

# Read in common settings
ifneq ("$(wildcard $(COMMON_FILE))","")
include $(COMMON_FILE)
else
endif

CFLAGS = -I../../include -Wall -O2 -g $(MARCHABISTRING)

SRC = $(wildcard *.c)
OBJ = $(patsubst %.c, %.o, $(SRC))

all: $(OBJ) 

%o: %c
	$(CC) -c $< -o $@

clean:
	rm -f $(OBJ)
