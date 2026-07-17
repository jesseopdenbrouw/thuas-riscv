#
# makefile to run the GHDL simulator
#
# make - compiles and simulates the VHDL code and start GTKwave
#
# make run - compiles and simulates the VHDL code
#
# Note: ghdl logs all signals so the wave file will become
#       very big with simulation times > 1 ms
#


BUILDDIR = build
VHDLDIR = ../../rtl/thuas-riscv
TOPLEVEL = tb_riscv
RUNTIME = 1ms

GHDL = ghdl
GTKWAVE = gtkwave

SRCS = $(wildcard $(VHDLDIR)/*.vhd)

ifneq ($(MAKECMDGOALS),run)
WAVEFLAGS = --wave=$(BUILDDIR)/tb_riscv.ghw
else
WAVEFLAGS =
endif

.PHONY: all clean build run wave

all: wave

build: $(SRCS)
	mkdir -p $(BUILDDIR)
	$(GHDL) -i -Wno-hide --workdir=$(BUILDDIR) $(SRCS)
	$(GHDL) -m -Wno-hide -fsynopsys --workdir=$(BUILDDIR) $(TOPLEVEL)

run: build
	$(GHDL) -r -fsynopsys --workdir=$(BUILDDIR) $(TOPLEVEL) --ieee-asserts=disable --max-stack-alloc=0 --stop-time=$(RUNTIME) $(WAVEFLAGS)

wave: run
	$(GTKWAVE) -S tb_riscv.tcl $(BUILDDIR)/tb_riscv.ghw

clean:
	rm -f tb_riscv.ghw work-obj93.cf output.txt
	rm -rf $(BUILDDIR)

