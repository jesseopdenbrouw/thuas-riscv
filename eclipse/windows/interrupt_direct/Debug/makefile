################################################################################
# Automatically-generated file. Do not edit!
################################################################################

-include ../makefile.init

RM := rm -rf

# All of the sources participating in the build are defined here
-include sources.mk
-include src/subdir.mk
-include lib/wdt/subdir.mk
-include lib/util/subdir.mk
-include lib/uart/subdir.mk
-include lib/timer/subdir.mk
-include lib/spi/subdir.mk
-include lib/i2c/subdir.mk
-include lib/gpio/subdir.mk
-include lib/csr/subdir.mk
-include crt/subdir.mk
-include subdir.mk
-include objects.mk

ifneq ($(MAKECMDGOALS),clean)
ifneq ($(strip $(SX_DEPS)),)
-include $(SX_DEPS)
endif
ifneq ($(strip $(ASM_DEPS)),)
-include $(ASM_DEPS)
endif
ifneq ($(strip $(S_UPPER_DEPS)),)
-include $(S_UPPER_DEPS)
endif
ifneq ($(strip $(C_DEPS)),)
-include $(C_DEPS)
endif
endif

-include ../makefile.defs

OPTIONAL_TOOL_DEPS := \
$(wildcard ../makefile.defs) \
$(wildcard ../makefile.init) \
$(wildcard ../makefile.targets) \


BUILD_ARTIFACT_NAME := interrupt_direct
BUILD_ARTIFACT_EXTENSION := elf
BUILD_ARTIFACT_PREFIX :=
BUILD_ARTIFACT := $(BUILD_ARTIFACT_PREFIX)$(BUILD_ARTIFACT_NAME)$(if $(BUILD_ARTIFACT_EXTENSION),.$(BUILD_ARTIFACT_EXTENSION),)

# Add inputs and outputs from these tool invocations to the build variables 
SECONDARY_FLASH += \
interrupt_direct.srec \

SECONDARY_SIZE += \
interrupt_direct.siz \


# All Target
all: main-build

# Main-build Target
main-build: interrupt_direct.elf secondary-outputs

# Tool invocations
interrupt_direct.elf: $(OBJS) $(USER_OBJS) makefile objects.mk $(OPTIONAL_TOOL_DEPS)
	@echo 'Building target: $@'
	@echo 'Invoking: GNU RISC-V Cross C Linker'
	riscv-none-elf-gcc.cmd -march=rv32im_zicsr -mabi=ilp32 -msmall-data-limit=8 -mno-save-restore -O0 -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections -g3 -T "D:\PROJECTS\RISCVDEV\thuas-riscv-with-new-io\eclipse\windows\interrupt_direct\ldfiles\riscv.ld" -nostartfiles -Xlinker --gc-sections -Wl,-Map,"interrupt_direct.map" --specs=nano.specs -o "interrupt_direct.elf" $(OBJS) $(USER_OBJS) $(LIBS)
	@echo 'Finished building target: $@'
	@echo ' '

interrupt_direct.srec: interrupt_direct.elf makefile objects.mk $(OPTIONAL_TOOL_DEPS)
	@echo 'Invoking: GNU RISC-V Cross Create Flash Image'
	riscv-none-elf-objcopy.cmd -O srec "interrupt_direct.elf"  "interrupt_direct.srec"
	@echo 'Finished building: $@'
	@echo ' '

interrupt_direct.siz: interrupt_direct.elf makefile objects.mk $(OPTIONAL_TOOL_DEPS)
	@echo 'Invoking: GNU RISC-V Cross Print Size'
	riscv-none-elf-size.cmd --format=berkeley "interrupt_direct.elf"
	@echo 'Finished building: $@'
	@echo ' '

# Other Targets
clean:
	-$(RM) $(SX_DEPS)$(OBJS)$(SECONDARY_FLASH)$(SECONDARY_SIZE)$(ASM_DEPS)$(S_UPPER_DEPS)$(C_DEPS) interrupt_direct.elf
	-@echo ' '

secondary-outputs: $(SECONDARY_FLASH) $(SECONDARY_SIZE)

.PHONY: all clean dependents main-build

-include ../makefile.targets
