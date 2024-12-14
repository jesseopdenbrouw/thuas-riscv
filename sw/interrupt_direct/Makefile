#
# Makefile to build target
#

#
# NOTE: we link against the default nano library,
#       to make use of ECALL for system calls
#

# The target
TARGET = interrupt_direct


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

# Linker flags
#LDFLAGS = -g -lm -Wall -nostartfiles -T $(LD_SCRIPT) $(LIBTHUASRV32STRING) $(MARCHABISTRING) --specs=../lib/thuas.specs --specs=nano.specs $(EXTRA_LINKER_FLAGS)
LDFLAGS = -g -lm -Wall -nostartfiles -T $(LD_SCRIPT) $(LIBTHUASRV32STRING) $(MARCHABISTRING) --specs=nano.specs --specs=../lib/thuas.specs $(EXTRA_LINKER_FLAGS)

# All header files
HFILES = $(wildcard *.h)

# Find all C files and transform to object files
SRCS = $(wildcard *.c) $(CRT)
OBJS = $(sort $(patsubst %.c, %.o, $(SRCS)))
# Object file startup
OBJCRT = $(sort $(patsubst %.c, %.o, $(CRT)))

.PHONY: all
all: $(CRT) $(TARGET).elf

# Make a copy of the crt in this directory and compile it
$(CRT):
	cp $(CRT_PATH)/$(CRT) .
	$(CC) $(CFLAGS) -c $(CRT) -o $(OBJCRT)

# Compile a C files
%.o: %.c $(HFILES) $(COMMON_FILE)
	$(CC) $(CFLAGS) -c $< -o $@

# Build the target
$(TARGET).elf: $(OBJS) $(HFILES) $(COMMON_FILE)
	$(CC) -o $(TARGET).elf $(OBJS) $(LDFLAGS)
	$(OBJCOPY) -O srec $(TARGET).elf $(TARGET).srec
	$(SREC2VHDL) -wf $(TARGET).srec $(TARGET).vhd
	$(SIZE) $(TARGET).elf

.PHONY: upload
# Upload the S-record file
upload: $(TARGET).srec
	$(UPLOAD) $(UPLOAD_OPTIONS) $(TARGET).srec

.PHONY: clean
# Clean all
clean:
	rm -f $(TARGET).elf $(TARGET).srec $(TARGET).vhd $(OBJS) $(CRT)

