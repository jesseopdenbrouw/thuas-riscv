PREFIX := ../../rtl/thuas-riscv

# Note: ghdl does not expose records
SIM := questa
TOPLEVEL_LANG := vhdl

# Top-level VHDL entity
TOPLEVEL := de0_cv

# Python test module (without .py)
COCOTB_TEST_MODULES := test_top

# VHDL source files
#VHDL_SOURCES := $(wildcard $(PREFIX)/*.vhd)
#VHDL_SOURCES := $(filter-out $(PREFIX)/tb_riscv.vhd,$(VHDL_SOURCES))
#VHDL_SOURCES := $(PREFIX)/processor_common.vhd $(VHDL_SOURCES)

VHDL_SOURCES := \
			$(PREFIX)/processor_common.vhd \
			$(PREFIX)/rom_image.vhd \
			$(PREFIX)/bootrom_image.vhd \
			$(PREFIX)/ram_image.vhd \
			$(PREFIX)/address_decode.vhd \
			$(PREFIX)/core.vhd \
			$(PREFIX)/crc.vhd \
			$(PREFIX)/dm.vhd \
			$(PREFIX)/dtm.vhd \
			$(PREFIX)/gpio.vhd \
			$(PREFIX)/i2c.vhd \
			$(PREFIX)/instr_router.vhd \
			$(PREFIX)/io_bus_switch.vhd \
			$(PREFIX)/mem.vhd \
			$(PREFIX)/msi.vhd \
			$(PREFIX)/mtime.vhd \
			$(PREFIX)/spi.vhd \
			$(PREFIX)/stub.vhd \
			$(PREFIX)/timera.vhd \
			$(PREFIX)/timerb.vhd \
			$(PREFIX)/uart.vhd \
			$(PREFIX)/wdt.vhd \
			$(PREFIX)/riscv.vhd \
			rtl/de0_cv.vhd

export COCOTB_LOG_LEVEL = INFO
export VHDL_GPI_INTERFACE = vhpi

#EXTRA_ARGS += -fsynopsys
#SIM_ARGS += -voptargs=+acc

include $(shell cocotb-config --makefiles)/Makefile.sim

