-- #################################################################################################
-- # gpio.vhd - General purpose I/O and edge detector                                              #
-- # ********************************************************************************************* #
-- # This file is part of the THUAS RISCV RV32 Project                                             #
-- # ********************************************************************************************* #
-- # BSD 3-Clause License                                                                          #
-- #                                                                                               #
-- # Copyright (c) 2024, Jesse op den Brouw. All rights reserved.                                  #
-- #                                                                                               #
-- # Redistribution and use in source and binary forms, with or without modification, are          #
-- # permitted provided that the following conditions are met:                                     #
-- #                                                                                               #
-- # 1. Redistributions of source code must retain the above copyright notice, this list of        #
-- #    conditions and the following disclaimer.                                                   #
-- #                                                                                               #
-- # 2. Redistributions in binary form must reproduce the above copyright notice, this list of     #
-- #    conditions and the following disclaimer in the documentation and/or other materials        #
-- #    provided with the distribution.                                                            #
-- #                                                                                               #
-- # 3. Neither the name of the copyright holder nor the names of its contributors may be used to  #
-- #    endorse or promote products derived from this software without specific prior written      #
-- #    permission.                                                                                #
-- #                                                                                               #
-- # THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS   #
-- # OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF               #
-- # MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE    #
-- # COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,     #
-- # EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE #
-- # GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED    #
-- # AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING     #
-- # NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED  #
-- # OF THE POSSIBILITY OF SUCH DAMAGE.                                                            #
-- # ********************************************************************************************* #
-- # https:/github.com/jesseopdenbrouw/thuas-riscv                                                 #
-- #################################################################################################

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.processor_common.all;

entity gpio is
    port (I_clk : in std_logic;
          I_areset : in std_logic;
          -- 
          I_mem_request : in mem_request_type;
          O_mem_response : out mem_response_type;
          --
          I_pin : in data_type;
          O_pout: out data_type;
          O_irq : out std_logic
         );
end entity gpio;

architecture rtl of gpio is

type gpio_type is record
    pinsync : data_type;
    pout : data_type;
    edge : std_logic_vector(1 downto 0);
    pinnr : std_logic_vector(4 downto 0);
    detect : std_logic;
    detectsync : std_logic_vector(1 downto 0);
end record;

signal gpio : gpio_type;
signal isword : boolean;
-- For strobing
signal cs_sync : std_logic;

begin

    O_mem_response.load_misaligned_error <= '1' when I_mem_request.cs = '1' and I_mem_request.wren = '0' and I_mem_request.size /= memsize_word else '0';
    O_mem_response.store_misaligned_error <= '1' when I_mem_request.cs = '1' and I_mem_request.wren = '1' and I_mem_request.size /= memsize_word else '0';
    isword <= I_mem_request.size = memsize_word;
    
    process (I_clk, I_areset) is
    begin
        if I_areset = '1' then
            gpio.pout <= all_zeros_c;
            gpio.pinsync <= all_zeros_c;
            gpio.edge <= (others => '0');
            gpio.pinnr <= (others => '0');
            gpio.detectsync <= (others => '0');
            gpio.detect <= '0';
            --
            O_mem_response.data <= all_zeros_c;
            O_mem_response.ready <= '0';
            cs_sync <= '0';
        elsif rising_edge(I_clk) then
            O_mem_response.data <= all_zeros_c;
            O_mem_response.ready <= '0';
            cs_sync <= I_mem_request.cs;
            gpio.pinsync <= I_pin;
            gpio.detectsync <= gpio.detectsync(0) & I_pin(to_integer(unsigned(gpio.pinnr)));
            if I_mem_request.cs = '1' and cs_sync = '0' and isword then
                -- Write
                if I_mem_request.wren = '1' then
                    -- Write on read-only GPIO inputs: ignore (0x00)
                    if I_mem_request.addr(4 downto 2) = "000" then
                        null;
                    -- Write on GPIO outputs (0x04)
                    elsif I_mem_request.addr(4 downto 2) = "001" then
                        gpio.pout <= I_mem_request.data;
                    -- Write GPIO external ctrl register (0x18)
                    elsif I_mem_request.addr(4 downto 2) = "110" then
                        gpio.pinnr <= I_mem_request.data(7 downto 3);
                        gpio.edge <= I_mem_request.data(2 downto 1);
                    -- Write GPIO external stat register (0x1c)
                    elsif I_mem_request.addr(4 downto 2) = "111" then
                        gpio.detect <= I_mem_request.data(0);
                    end if;
                -- Read
                else
                    if I_mem_request.addr(4 downto 2) = "000" then
                        -- Read from external inputs
                        O_mem_response.data <= gpio.pinsync;
                    elsif I_mem_request.addr(4 downto 2) = "001" then
                        -- Read from external outputs
                        O_mem_response.data <= gpio.pout;
                    elsif I_mem_request.addr(4 downto 2) = "110" then
                        -- Read from external interrupt control register
                        O_mem_response.data(7 downto 3) <= gpio.pinnr;
                        O_mem_response.data(2 downto 1) <= gpio.edge;
                    elsif I_mem_request.addr(4 downto 2) = "111" then
                        -- Read from external interrupt status register
                        O_mem_response.data <= all_zeros_c;
                        O_mem_response.data(0) <= gpio.detect;
                    end if;
                end if;
                O_mem_response.ready <= '1';
            end if;
           -- Detect rising edge or falling edge or both
            if (gpio.edge(0) = '1' and gpio.detectsync(1) = '0' and gpio.detectsync(0) = '1') or
               (gpio.edge(1) = '1' and gpio.detectsync(1) = '1' and gpio.detectsync(0) = '0') then
                gpio.detect <= '1';
            end if;
        end if;
    end process;

    O_pout <= gpio.pout;
    O_irq <= gpio.detect;
    
end architecture rtl;