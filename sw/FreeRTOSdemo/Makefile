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

# Set to 0 to run the comprehensive demo, set to 1 to run the simply blinky demo
WHICH_DEMO ?= mainCREATE_SIMPLE_BLINKY_DEMO_ONLY=0
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

# FreeRTOS sources for the full_demo
APP_SRC += $(FREERTOS_HOME)/FreeRTOS/Demo/Common/Minimal/blocktim.c
APP_SRC += $(FREERTOS_HOME)/FreeRTOS/Demo/Common/Minimal/dynamic.c
APP_SRC += $(FREERTOS_HOME)/FreeRTOS/Demo/Common/Minimal/EventGroupsDemo.c
APP_SRC += $(FREERTOS_HOME)/FreeRTOS/Demo/Common/Minimal/GenQTest.c
APP_SRC += $(FREERTOS_HOME)/FreeRTOS/Demo/Common/Minimal/recmutex.c
APP_SRC += $(FREERTOS_HOME)/FreeRTOS/Demo/Common/Minimal/TaskNotify.c
APP_SRC += $(FREERTOS_HOME)/FreeRTOS/Demo/Common/Minimal/TaskNotifyArray.c
APP_SRC += $(FREERTOS_HOME)/FreeRTOS/Demo/Common/Minimal/TimerDemo.c

APP_INC += -I $(FREERTOS_HOME)/FreeRTOS/Demo/Common/include

# THUASRV32 specific
ASM_INC += -DportasmHANDLE_INTERRUPT=SystemIrqHandler

APP_INC += -I chip_specific_extensions/thuasrv32

ASM_INC += -I chip_specific_extensions/thuasrv32

# Demo application
APP_SRC += blinky_demo/main_blinky.c
APP_SRC += full_demo/main_full.c
APP_SRC += full_demo/RegTest.s


# Modify this variable to fit your THUASRV32 setup (THUASRV32 home folder)
THUASRV32_HOME ?= ../

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
	$(CC) $(EFFORT) -g -o $(TARGET).elf $(LDFLAGS) -D$(WHICH_DEMO) -I$(INCPATH) $(APP_INC) $(APP_SRC) $(CRT) -DF_CPU=$(F_CPU) -DBAUD_RATE=$(BAUD_RATE) -DPROG_NAME=$(PROG_NAME)
	$(OBJCOPY) -O srec $(TARGET).elf $(TARGET).srec
	$(SREC2VHDL) -wf $(TARGET).srec $(TARGET).vhd
	$(SIZE) $(TARGET).elf

.PHONY: upload
# Upload the S-record file
upload: $(TARGET).srec
	$(UPLOAD) $(UPLOAD_OPTIONS) $(TARGET).srec

.PHONY: clean_all
clean:
	rm -f $(TARGET).elf $(TARGET).srec $(TARGET).vhd $(CRT)
