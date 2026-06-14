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



#**************************************************************
# Set Output Delay
#**************************************************************



#**************************************************************
# Set Clock Groups
#**************************************************************



#**************************************************************
# Set False Path
#**************************************************************

set_false_path -from [get_ports I_areset]

set_false_path -from [get_ports I_trst]
set_false_path -from [get_ports I_tck]
set_false_path -from [get_ports I_tms]
set_false_path -from [get_ports I_tdi]

set_false_path -from [get_ports I_gpioapin*]

set_false_path -from [get_ports I_uart1rxd]
#set_false_path -from [get_ports I_uart2rxd]

set_false_path -from [get_ports IO_i2c1scl]
set_false_path -from [get_ports IO_i2c1sda]

set_false_path -from [get_ports IO_i2c2scl]
set_false_path -from [get_ports IO_i2c2sda]

set_false_path -from [get_ports I_spi1miso]
set_false_path -from [get_ports I_spi2miso]

set_false_path -from [get_ports IO_timer2icoca]
set_false_path -from [get_ports IO_timer2icocb]
set_false_path -from [get_ports IO_timer2icocc]

set_false_path -to [get_ports O_tdo]

set_false_path -to [get_ports O_gpioapout*]

set_false_path -to [get_ports O_uart1txd]
#set_false_path -to [get_ports O_uart2txd]

set_false_path -to [get_ports IO_i2c1scl]
set_false_path -to [get_ports IO_i2c1sda]

set_false_path -to [get_ports IO_i2c2scl]
set_false_path -to [get_ports IO_i2c2sda]

set_false_path -to [get_ports O_spi1sck]
set_false_path -to [get_ports O_spi1mosi]
set_false_path -to [get_ports O_spi2sck]
set_false_path -to [get_ports O_spi2mosi]

set_false_path -to [get_ports O_timer2oct]
set_false_path -to [get_ports IO_timer2icoca]
set_false_path -to [get_ports IO_timer2icocb]
set_false_path -to [get_ports IO_timer2icocc]

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

