#################################################################################################
# tb_riscv.do - QuestaSim/ModelSim command file for simulation                                  #
# ********************************************************************************************* #
# This file is part of the THUAS RISCV RV32 Project                                             #
# ********************************************************************************************* #
# BSD 3-Clause License                                                                          #
#                                                                                               #
# Copyright (c) 2025, Jesse op den Brouw. All rights reserved.                                  #
#                                                                                               #
# Redistribution and use in source and binary forms, with or without modification, are          #
# permitted provided that the following conditions are met:                                     #
#                                                                                               #
# 1. Redistributions of source code must retain the above copyright notice, this list of        #
#    conditions and the following disclaimer.                                                   #
#                                                                                               #
# 2. Redistributions in binary form must reproduce the above copyright notice, this list of     #
#    conditions and the following disclaimer in the documentation and/or other materials        #
#    provided with the distribution.                                                            #
#                                                                                               #
# 3. Neither the name of the copyright holder nor the names of its contributors may be used to  #
#    endorse or promote products derived from this software without specific prior written      #
#    permission.                                                                                #
#                                                                                               #
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS   #
# OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF               #
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE    #
# COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,     #
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE #
# GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED    #
# AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING     #
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED  #
# OF THE POSSIBILITY OF SUCH DAMAGE.                                                            #
# ********************************************************************************************* #
# https:/github.com/jesseopdenbrouw/thuas-riscv                                                 #
#################################################################################################

# Transcript on
transcript on

# Recreate work library
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

# Find out if we're started through Quartus or by hand
# (or by using an exec in the Tcl window in Quartus).
# Quartus has the annoying property that it will start
# Questasim from a directory called "simulation/questa".
# The design and the testbench are located in the project
# root, so we've to compensate for that.
if [ string match "*simulation/questa" [pwd] ] { 
	set prefix "../../"
	puts "Running Questasim from Quartus..."
} else {
	set prefix ""
	puts "Running Questasim..."
}

# Compile the VHDL description and testbench,
# please note that the design and its testbench are located
# in the project root, but the simulator start in directory
# <project_root>/simulation/modelsim, so we have to compensate
# for that.
vcom -93 -work work ${prefix}processor_common.vhd
vcom -93 -work work ${prefix}rom_image.vhd
vcom -93 -work work ${prefix}rom.vhd
vcom -93 -work work ${prefix}bootrom_image.vhd
vcom -93 -work work ${prefix}bootrom.vhd
vcom -93 -work work ${prefix}ram.vhd
vcom -93 -work work ${prefix}core.vhd
vcom -93 -work work ${prefix}address_decode.vhd
vcom -93 -work work ${prefix}instr_router.vhd
vcom -93 -work work ${prefix}dm.vhd
vcom -93 -work work ${prefix}dtm.vhd
vcom -93 -work work ${prefix}io_bus_switch.vhd
vcom -93 -work work ${prefix}gpio.vhd
vcom -93 -work work ${prefix}uart.vhd
vcom -93 -work work ${prefix}timera.vhd
vcom -93 -work work ${prefix}i2c.vhd
vcom -93 -work work ${prefix}spi.vhd
vcom -93 -work work ${prefix}timerb.vhd
vcom -93 -work work ${prefix}wdt.vhd
vcom -93 -work work ${prefix}msi.vhd
vcom -93 -work work ${prefix}mtime.vhd
vcom -93 -work work ${prefix}riscv.vhd
vcom -93 -work work ${prefix}crc.vhd
vcom -93 -work work ${prefix}tb_riscv.vhd

# Start the simulator
vsim -t 1ns -L rtl_work -L work -voptargs="+acc" tb_riscv

# Log all signals in the design, good if the number
# of signals is small.
add log -r *

# Add all toplevel signals
# Add a number of signals of the simulated design
add wave -divider "Inputs"
add wave            -label clk clk
add wave            -label areset areset
add wave -radix hex -label gpioapin gpioapin
add wave -radix hex -label uart1rxd uart1rxd
add wave -divider "Outputs"
add wave -radix hex -label gpioapout gpioapout
add wave -radix hex -label uart1txd uart1txd
add wave            -label timer2oct timer2oct
add wave            -label timer2icoca timer2icoca
add wave            -label timer2icocb timer2icocb
add wave            -label timer2icocc timer2icocc
add wave -divider "tOP - Resets"
add wave            -label areset_sys_sync_int dut/areset_sys_sync_int
add wave            -label areset_sys_int dut/areset_sys_int
add wave            -label break_from_uart1_int dut/break_from_uart1_int
add wave            -label reset_from_wdt dut/reset_from_wdt_int
add wave            -label areset_debug_sync_int dut/areset_debug_sync_int
add wave            -label areset_debug_int dut/areset_debug_int
add wave -divider "Core Internals - Control"
add wave            -label control dut/core0/control
add wave -divider "Core Internals - Instruction Fetch"
add wave            -label pc dut/core0/pc
add wave            -label if_id dut/core0/if_id
add wave -divider "Core Internals - Instruction Decode"
add wave            -label id_ex dut/core0/id_ex
add wave -divider "Core Internals - Execute & Write back"
add wave            -label ex_wb dut/core0/ex_wb
add wave -divider "Core Internals - Registers"
# Registers are spread over three instances (rs1, rs2, debug)
add wave            -label regs dut/core0/regs_rs1
add wave -divider "Core Internals - Execute MD"
add wave            -label md dut/core0/md
add wave -divider "Internals - Memory access"
add wave            -label bus_request dut/bus_request_int
add wave            -label bus_response dut/bus_response_int
add wave -divider "Internals - CSR"
add wave -radix hex -label CSR_access dut/core0/csr_access
add wave -radix hex -label CSR_reg dut/core0/csr_reg
add wave -divider "Internals - RAM"
add wave            -label RAM_mem_request dut/mem_request_ram_int
add wave            -label RAM_mem_response dut/mem_response_ram_int
add wave -radix hex -label RAM_sim dut/ram0/ram_alt
#add wave -divider "Internals - ROMs"
#add wave -radix hex -label rom dut/rom
add wave -divider "Internals - IO"
add wave            -label IO_mem_request dut/mem_request_io_int
add wave            -label IO_mem_response dut/mem_response_io_int
add wave -radix hex -label gpioa_rec dut/gpioa/gpio
add wave -radix hex -label mtime_rec dut/mtime1/mtime
if {[find signal -r */wdt1gen/*] != ""} {
    add wave -radix hex -label wdt_rec dut/wdt1gen/wdt1/wdt
}
if {[find signal -r */msi1gen/*] != ""} {
    add wave            -label msi_rec dut/msi1gen/msi1/msi
}
if {[find signal -r */timer1gen/*] != ""} {
    add wave            -label timer1_rec dut/timer1gen/timer1/timera
}
if {[find signal -r */uart1gen/*] != ""} {
    add wave            -label uart1_rec dut/uart1gen/uart1/uart
}
if {[find signal -r */uart2gen/*] != ""} {
    add wave            -label uart2_rec dut/uart2gen/uart2/uart
}
if {[find signal -r */i2c1gen/*] != ""} {
    add wave            -label i2c1_rec dut/i2c1gen/i2c1/i2c
}
if {[find signal -r */i2c2gen/*] != ""} {
    add wave            -label i2c2_rec dut/i2c2gen/i2c2/i2c
}
if {[find signal -r */spi1gen/*] != ""} {
    add wave            -label spi1_rec dut/spi1gen/spi1/spi
}
if {[find signal -r */spi1gen/*] != ""} {
    add wave            -label spi2_rec dut/spi2gen/spi2/spi
}
if {[find signal -r */timer2gen/*] != ""} {
    add wave            -label timer2_rec dut/timer2gen/timer2/timerb
}
if {[find signal -r */crcgen/*] != ""} {
    add wave            -label crc_rec dut/crcgen/crc1/crc
}

# Open Structure, Signals (waveform) and List window
view structure
#view list
view signals

# Disable NUMERIC STD Warnings
# This will speed up simulation considerably
# and prevents writing to the transcript file
set NumericStdNoWarnings 1

# Run simulation for xx us
run 100 us

# Fill up the waveform in the window
wave zoom full
