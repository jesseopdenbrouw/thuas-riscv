#
# makefile to run the GHDL simulator
#


BUILDDIR = build
VHDLDIR = ../rtl/thuas-riscv
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

all: run wave

build: $(SRCS)
	mkdir -p $(BUILDDIR)
	$(GHDL) -i -Wno-hide --workdir=$(BUILDDIR) $(SRCS)
	$(GHDL) -m -Wno-hide -fsynopsys --workdir=$(BUILDDIR) $(TOPLEVEL)

run: build
	$(GHDL) -r -fsynopsys --workdir=$(BUILDDIR) $(TOPLEVEL) --ieee-asserts=disable --max-stack-alloc=0 --stop-time=$(RUNTIME) $(WAVEFLAGS)

wave:
	$(GTKWAVE) -S tb_riscv.tcl $(BUILDDIR)/tb_riscv.ghw

clean:
	rm -f tb_riscv.ghw work-obj93.cf output.txt
	rm -rf $(BUILDDIR)

