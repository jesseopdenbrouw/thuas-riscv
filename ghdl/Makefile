
#
# Makefile for simulating the THUASRV32 soc with
# GHDL and viewing the waveforms with GTKWave

PREFIX = ../rtl/thuas-riscv

NOENT = \
       processor_common.vhd \
       bootrom_image.vhd \
       rom_image.vhd \

FILES = \
		address_decode.vhd \
		bootrom.vhd \
        crc.vhd \
		core.vhd \
		dm.vhd \
		dtm.vhd \
		gpio.vhd \
		i2c.vhd \
		instr_router.vhd \
		io_bus_switch.vhd \
		msi.vhd \
		mtime.vhd \
		ram.vhd \
		riscv.vhd \
		rom.vhd \
		spi.vhd \
		tb_riscv.vhd \
		timera.vhd \
		timerb.vhd \
		uart.vhd \
		wdt.vhd \
		stub.vhd

ENTITIES = $(basename $(FILES))


all: compile sim wave

compile:
	@echo "Compiling..."
	@for i in $(NOENT) $(FILES); do ghdl -a $(PREFIX)/$$i; done
	@for i in $(ENTITIES); do ghdl -e $$i; done

sim:
	@echo "Running the simulation..."
	./tb_riscv --wave=tb_riscv.ghw --stop-time=1000us --ieee-asserts=disable --max-stack-alloc=1024

wave:
	@echo "Starting GTKWave (takes a long time...)"
	@gtkwave -S tb_riscv.tcl tb_riscv.ghw

clean:
	ghdl --clean
	rm -f tb_riscv.ghw work-obj93.cf

