
#
# Makefile for simulating the THUASRV32 soc with
# GHDL and viewing the waveforms with GTKWave

PREFIX = ../rtl/thuas-riscv

all: compile sim wave

compile:
	echo "Compiling all VHDL files..."
	ghdl -a $(PREFIX)/processor_common.vhd
	ghdl -a $(PREFIX)/rom_image.vhd
	ghdl -a $(PREFIX)/bootrom_image.vhd
	ghdl -a $(PREFIX)/address_decode.vhd $(PREFIX)/instr_router.vhd  $(PREFIX)/bootloader.vhd $(PREFIX)/io.vhd $(PREFIX)/core.vhd $(PREFIX)/ram.vhd $(PREFIX)/rom.vhd $(PREFIX)/riscv.vhd $(PREFIX)/dm.vhd $(PREFIX)/dtm.vhd $(PREFIX)/tb_riscv.vhd
	ghdl -e address_decode
	ghdl -e instruction_router
	ghdl -e bootloader
	ghdl -e io
	ghdl -e core
	ghdl -e rom
	ghdl -e riscv
	ghdl -e dm
	ghdl -e dtm
	ghdl -e tb_riscv

sim:
	echo "Running the simulation..."
	./tb_riscv --wave=tb_riscv.ghw --stop-time=1000us --ieee-asserts=disable --max-stack-alloc=1024

wave:
	echo "Starting GTKWave (takes a long time...)"
	gtkwave -S tb_riscv.tcl tb_riscv.ghw

clean:
	ghdl --clean
	rm -f tb_riscv.ghw work-obj93.cf

