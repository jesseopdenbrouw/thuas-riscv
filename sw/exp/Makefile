#
# Makefile to build target
#


# The target
TARGET = exp



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
	$(CC) -g -o $(TARGET).elf $(OBJS) $(LDFLAGS)
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

