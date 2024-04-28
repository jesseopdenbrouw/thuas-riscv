#
# Makefile for creating the WDT library
# for the THUAS RISC-V RV32 project.
# See: https://github.com/jesseopdenbrouw/thuas-riscv
#

# Include common defines
COMMON_FILE = ../../common.make

# Read in common settings
ifneq ("$(wildcard $(COMMON_FILE))","")
include $(COMMON_FILE)
else
endif

CFLAGS += -I../../include

SRC = $(wildcard *.c)
OBJ = $(patsubst %.c, %.o, $(SRC))

all: $(OBJ) 

%o: %c
	$(CC) -c $< -o $@

clean:
	rm -f $(OBJ)
