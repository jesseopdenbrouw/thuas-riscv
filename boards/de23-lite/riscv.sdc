#################################################################################################
# riscv.sdc - Design Constraints for the THUAS RISCV processor                                  #
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

#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3



#**************************************************************
# Create Clock
#**************************************************************

#  50.00 MHz
create_clock -name {I_clk} -period 20.000 -waveform { 0.000 10.000 } [get_ports {I_clk}]
#  66.67 MHz
#create_clock -name {I_clk} -period 15.000 -waveform { 0.000 7.500 } [get_ports {I_clk}]
#  100.00 MHz
#create_clock -name {I_clk} -period 10.000 -waveform { 0.000 5.000 } [get_ports {I_clk}]
#  125.00 MHz
#create_clock -name {I_clk} -period 8.000 -waveform { 0.000 4.000 } [get_ports {I_clk}]
#  150.00 MHz
#create_clock -name {I_clk} -period 6.000 -waveform { 0.000 3.000 } [get_ports {I_clk}]
#  200.00 MHz
#create_clock -name {I_clk} -period 5.000 -waveform { 0.000 2.500 } [get_ports {I_clk}]


#**************************************************************
# Create Generated Clock
#**************************************************************


	 
#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************



#**************************************************************
# Set Input Delay
#**************************************************************

#set_input_delay -clock [get_clocks pll0|iopll_0|tennm_ph2_iopll~O_OUT_CLK0 -nocase] -max -rise 2.0 [get_ports {IO_i2c1scl IO_i2c1sda IO_i2c2scl IO_i2c2sda IO_timer2icoca IO_timer2icocb IO_timer2icocc I_gpioapin[0] I_gpioapin[1] I_gpioapin[2] I_gpioapin[3] I_gpioapin[4] I_gpioapin[5] I_gpioapin[6] I_gpioapin[7] I_gpioapin[8] I_gpioapin[9] I_gpioapin[10] I_gpioapin[11] I_gpioapin[12] I_gpioapin[13] I_gpioapin[14] I_gpioapin[15] I_spi1miso I_spi2miso I_tck I_tdi I_tms I_trst I_uart1rxd}]
#set_input_delay -clock [get_clocks pll0|iopll_0|tennm_ph2_iopll~O_OUT_CLK0 -nocase] -min -rise 1.4 [get_ports {IO_i2c1scl IO_i2c1sda IO_i2c2scl IO_i2c2sda IO_timer2icoca IO_timer2icocb IO_timer2icocc I_gpioapin[0] I_gpioapin[1] I_gpioapin[2] I_gpioapin[3] I_gpioapin[4] I_gpioapin[5] I_gpioapin[6] I_gpioapin[7] I_gpioapin[8] I_gpioapin[9] I_gpioapin[10] I_gpioapin[11] I_gpioapin[12] I_gpioapin[13] I_gpioapin[14] I_gpioapin[15] I_spi1miso I_spi2miso I_tck I_tdi I_tms I_trst I_uart1rxd}]
#set_input_delay -clock [get_clocks pll0|iopll_0|tennm_ph2_iopll~O_OUT_CLK0 -nocase] -max -fall 2.0 [get_ports {IO_i2c1scl IO_i2c1sda IO_i2c2scl IO_i2c2sda IO_timer2icoca IO_timer2icocb IO_timer2icocc I_gpioapin[0] I_gpioapin[1] I_gpioapin[2] I_gpioapin[3] I_gpioapin[4] I_gpioapin[5] I_gpioapin[6] I_gpioapin[7] I_gpioapin[8] I_gpioapin[9] I_gpioapin[10] I_gpioapin[11] I_gpioapin[12] I_gpioapin[13] I_gpioapin[14] I_gpioapin[15] I_spi1miso I_spi2miso I_tck I_tdi I_tms I_trst I_uart1rxd}]
#set_input_delay -clock [get_clocks pll0|iopll_0|tennm_ph2_iopll~O_OUT_CLK0 -nocase] -min -fall 1.4 [get_ports {IO_i2c1scl IO_i2c1sda IO_i2c2scl IO_i2c2sda IO_timer2icoca IO_timer2icocb IO_timer2icocc I_gpioapin[0] I_gpioapin[1] I_gpioapin[2] I_gpioapin[3] I_gpioapin[4] I_gpioapin[5] I_gpioapin[6] I_gpioapin[7] I_gpioapin[8] I_gpioapin[9] I_gpioapin[10] I_gpioapin[11] I_gpioapin[12] I_gpioapin[13] I_gpioapin[14] I_gpioapin[15] I_spi1miso I_spi2miso I_tck I_tdi I_tms I_trst I_uart1rxd}]



#**************************************************************
# Set Output Delay
#**************************************************************

#set_output_delay -clock [get_clocks I_clk -nocase] -max -rise 2.0 [get_ports {IO_i2c1scl IO_i2c1sda IO_i2c2scl IO_i2c2sda IO_timer2icoca IO_timer2icocb IO_timer2icocc O_gpioapout[0] O_gpioapout[1] O_gpioapout[2] O_gpioapout[3] O_gpioapout[4] O_gpioapout[5] O_gpioapout[6] O_gpioapout[7] O_gpioapout[8] O_gpioapout[9] O_gpioapout[10] O_gpioapout[11] O_gpioapout[12] O_gpioapout[13] O_gpioapout[14] O_gpioapout[15] O_spi1mosi O_spi1sck O_spi2mosi O_spi2sck O_tdo O_timer2oct O_uart1txd O_uart2txd}]
#set_output_delay -clock [get_clocks I_clk -nocase] -min -rise 1.4 [get_ports {IO_i2c1scl IO_i2c1sda IO_i2c2scl IO_i2c2sda IO_timer2icoca IO_timer2icocb IO_timer2icocc O_gpioapout[0] O_gpioapout[1] O_gpioapout[2] O_gpioapout[3] O_gpioapout[4] O_gpioapout[5] O_gpioapout[6] O_gpioapout[7] O_gpioapout[8] O_gpioapout[9] O_gpioapout[10] O_gpioapout[11] O_gpioapout[12] O_gpioapout[13] O_gpioapout[14] O_gpioapout[15] O_spi1mosi O_spi1sck O_spi2mosi O_spi2sck O_tdo O_timer2oct O_uart1txd O_uart2txd}]
#set_output_delay -clock [get_clocks I_clk -nocase] -max -fall 2.0 [get_ports {IO_i2c1scl IO_i2c1sda IO_i2c2scl IO_i2c2sda IO_timer2icoca IO_timer2icocb IO_timer2icocc O_gpioapout[0] O_gpioapout[1] O_gpioapout[2] O_gpioapout[3] O_gpioapout[4] O_gpioapout[5] O_gpioapout[6] O_gpioapout[7] O_gpioapout[8] O_gpioapout[9] O_gpioapout[10] O_gpioapout[11] O_gpioapout[12] O_gpioapout[13] O_gpioapout[14] O_gpioapout[15] O_spi1mosi O_spi1sck O_spi2mosi O_spi2sck O_tdo O_timer2oct O_uart1txd O_uart2txd}]
#set_output_delay -clock [get_clocks I_clk -nocase] -min -fall 1.4 [get_ports {IO_i2c1scl IO_i2c1sda IO_i2c2scl IO_i2c2sda IO_timer2icoca IO_timer2icocb IO_timer2icocc O_gpioapout[0] O_gpioapout[1] O_gpioapout[2] O_gpioapout[3] O_gpioapout[4] O_gpioapout[5] O_gpioapout[6] O_gpioapout[7] O_gpioapout[8] O_gpioapout[9] O_gpioapout[10] O_gpioapout[11] O_gpioapout[12] O_gpioapout[13] O_gpioapout[14] O_gpioapout[15] O_spi1mosi O_spi1sck O_spi2mosi O_spi2sck O_tdo O_timer2oct O_uart1txd O_uart2txd}]


#**************************************************************
# Set Clock Groups
#**************************************************************



#**************************************************************
# Set False Path
#**************************************************************

set_false_path -from [get_ports I_areset]

#**************************************************************
# Set Multicycle Path
#**************************************************************



#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************

