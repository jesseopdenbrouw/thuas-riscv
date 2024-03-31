#
# Makefile for creating the THUASRV32 library
# for the THUAS RISC-V RV32 project.
# See: https://github.com/jesseopdenbrouw/riscv-rv32
#

# Include common defines
COMMON_FILE = ../common.make

# Read in common settings
ifneq ("$(wildcard $(COMMON_FILE))","")
include $(COMMON_FILE)
else
endif

CFLAGS = -I../include -Wall -O2 -g $(MARCHABISTRING)

LIBTHUASRV32 = libthuasrv32.a
SRC = $(wildcard */*.c)
OBJ = $(patsubst %.c, %.o, $(SRC))

.PHONY: all
all: $(LIBTHUASRV32)

$(LIBTHUASRV32): $(OBJ)
#	make -C syscalls all
#	make -C uart all
#	make -C util all
#	make -C csr all
#	make -C spi all
#	make -C i2c all
#	make -C timer all
#	make -C gpio all
	$(AR) rsv $(LIBTHUASRV32) $(OBJ)


.PHONY: clean
clean:
	make -C syscalls clean
	make -C uart clean
	make -C util clean
	make -C csr clean
	make -C spi clean
	make -C i2c clean
	make -C timer clean
	make -C gpio clean
	make -C wdt clean
	rm -f $(LIBTHUASRV32)
