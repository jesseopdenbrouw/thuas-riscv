#!/usr/bin/bash

set -e

cd $(dirname "$0")

mkdir -p build

find ../rtl/thuas-riscv -type f -name '*.vhd'  -exec \
  ghdl -i --workdir=build {} \;

ghdl -m --workdir=build tb_riscv

ghdl -r --workdir=build tb_riscv --ieee-asserts=disable --max-stack-alloc=0 --stop-time=1ms --wave=tb_riscv.ghw

gtkwave -S tb_riscv.tcl tb_riscv.ghw

ghdl --clean
rm -f tb_riscv.ghw work-obj93.cf
rm -rf build


