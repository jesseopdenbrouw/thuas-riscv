
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
		bootloader.vhd \
		core.vhd \
		de0_cv.vhd \
		dm.vhd \
		dtm.vhd \
		instr_router.vhd \
		io.vhd \
		ram.vhd \
		riscv.vhd \
		rom.vhd \
		tb_riscv.vhd

ENTITIES = $(basename $(FILES))


all: compile sim wave

compile:
	for i in $(NOENT) $(FILES); do ghdl -a $(PREFIX)/$$i; done
	for i in $(ENTITIES); do ghdl -e $$i; done

#	echo "Compiling all VHDL files..."

sim:
	echo "Running the simulation..."
	./tb_riscv --wave=tb_riscv.ghw --stop-time=1000us --ieee-asserts=disable --max-stack-alloc=1024

wave:
	echo "Starting GTKWave (takes a long time...)"
	gtkwave -S tb_riscv.tcl tb_riscv.ghw

clean:
	ghdl --clean
	rm -f tb_riscv.ghw work-obj93.cf

