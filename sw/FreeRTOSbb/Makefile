# *****************************************************************************
# USER CONFIGURATION
# *****************************************************************************

TARGET = main

APP_SRC = $(TARGET).c

# User's application include folders (don't forget the '-I' before each entry)
APP_INC ?= -I .
# User's application include folders - for assembly files only (don't forget the '-I' before each entry)
ASM_INC ?= -I .

# Optimization
EFFORT ?= -Os

# *****************************************************************************


# -----------------------------------------------------------------------------
# FreeRTOS
# -----------------------------------------------------------------------------
# FreeRTOS home folder (adapt this!)
#FREERTOS_HOME ?= /mnt/d/PROJECTS/RISCVDEV/FreeRTOS
FREERTOS_HOME ?= ../../../FreeRTOS

# FreeRTOS RISC-V specific
APP_SRC += $(wildcard $(FREERTOS_HOME)/FreeRTOS/Source/portable/GCC/RISC-V/*.c)
APP_SRC += $(FREERTOS_HOME)/FreeRTOS/Source/portable/GCC/RISC-V/portASM.S

APP_INC += -I $(FREERTOS_HOME)/FreeRTOS/Source/portable/GCC/RISC-V

# FreeRTOS core
APP_SRC += $(wildcard $(FREERTOS_HOME)/FreeRTOS/Source/*.c)
APP_SRC += $(wildcard $(FREERTOS_HOME)/FreeRTOS/Source/portable/MemMang/heap_4.c)

APP_INC += -I $(FREERTOS_HOME)/FreeRTOS/Source/include

APP_INC += -I $(FREERTOS_HOME)/FreeRTOS/Demo/Common/include

# THUASRV32 specific
ASM_INC += -DportasmHANDLE_INTERRUPT=SystemIrqHandler

APP_INC += -I chip_specific_extensions/thuasrv32

ASM_INC += -I chip_specific_extensions/thuasrv32

# BB application
APP_SRC += boundedbuffer.c

# Program name
PROG_NAME = \"$(TARGET)\"

# Include common defines
COMMON_FILE = ../common.make

# Read in common settings
ifneq ("$(wildcard $(COMMON_FILE))","")
include $(COMMON_FILE)
else
endif


.PHONY: all

all: $(TARGET).elf

$(TARGET).elf : $(APP_SRC) FreeRTOSConfig.h
	cp $(CRT_PATH)/$(CRT) .
	$(CC) $(EFFORT) -g -o $(TARGET).elf $(LDFLAGS) -I$(INCPATH) $(APP_INC) $(APP_SRC) $(CRT) -DF_CPU=$(F_CPU) -DBAUD_RATE=$(BAUD_RATE) -DPROG_NAME=$(PROG_NAME)
	$(OBJCOPY) -O srec $(TARGET).elf $(TARGET).srec
	$(SREC2VHDL) -wf $(TARGET).srec $(TARGET).vhd
	$(SIZE) $(TARGET).elf

.PHONY: upload
# Upload the S-record file
upload: $(TARGET).srec
	$(UPLOAD) $(UPLOAD_OPTIONS) $(TARGET).srec

.PHONY: ocd
ocd: $(TARGET).elf
	$(OPENOCD) -f $(OPENOCDCFG) -c "load_image $(TARGET).elf" -c "reset run" -c "shutdown"

.PHONY: clean
clean:
	rm -f $(TARGET).elf $(TARGET).srec $(TARGET).vhd $(CRT)
