-- #################################################################################################
-- # timera.vhd - Simple 32-bit timer with interrupt                                               #
-- # ********************************************************************************************* #
-- # This file is part of the THUAS RISCV RV32 Project                                             #
-- # ********************************************************************************************* #
-- # BSD 3-Clause License                                                                          #
-- #                                                                                               #
-- # Copyright (c) 2025, Jesse op den Brouw. All rights reserved.                                  #
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

-- This is the description of a simple 32-bits up counter with interrupt generation.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.processor_common.all;

entity timera is
    port (I_clk : in std_logic;
          I_areset : in std_logic;
          I_sreset : in std_logic;
          -- 
          I_mem_request : in mem_request_type;
          O_mem_response : out mem_response_type;
          --
          O_irq : out std_logic
         );
end entity timera;

architecture rtl of timera is

type timera_type is record
    en : std_logic;    -- Enable
    tcie : std_logic;  -- T Compare Interrupt Enable
    tc : std_logic;    -- T Compare Match
    --
    cntr : data_type;  -- Counter Register
    cmpt : data_type;  -- T Compare Match Register
end record;

signal timera : timera_type;
signal isword : boolean;

begin

    O_mem_response.load_misaligned_error <= '1' when I_mem_request.stb = '1' and I_mem_request.wren = '0' and (I_mem_request.size /= memsize_word or I_mem_request.addr(1 downto 0) /= "00") else '0';
    O_mem_response.store_misaligned_error <= '1' when I_mem_request.stb = '1' and I_mem_request.wren = '1' and (I_mem_request.size /= memsize_word  or I_mem_request.addr(1 downto 0) /= "00") else '0';
    isword <= I_mem_request.size = memsize_word and I_mem_request.addr(1 downto 0) = "00" ;

    process (I_clk, I_areset) is
    begin
        if I_areset = '1' then
            timera.en <= '0';
            timera.tcie <= '0';
            timera.tc <= '0';
            timera.cntr <= all_zeros_c;
            timera.cmpt <= all_zeros_c;
            --
            O_mem_response.data <= all_zeros_c;
            O_mem_response.ready <= '0';
        elsif rising_edge(I_clk) then
            O_mem_response.data <= all_zeros_c;
            O_mem_response.ready <= '0';
            
            if I_sreset = '1' then
                timera.en <= '0';
                timera.tcie <= '0';
                timera.tc <= '0';
                timera.cntr <= all_zeros_c;
                timera.cmpt <= all_zeros_c;
            else
                if I_mem_request.stb = '1' and isword then
                    if I_mem_request.wren = '1' then
                        case I_mem_request.addr(3 downto 2) is
                            when "00" =>
                                -- Write control register
                                timera.en <= I_mem_request.data(0);
                                timera.tcie <= I_mem_request.data(4);
                            when "01" =>
                                -- Write status register
                                timera.tc <= I_mem_request.data(4);
                            when "10" =>
                                -- Write counter register
                                timera.cntr <= I_mem_request.data;
                            when "11" =>
                               -- Write CMPT register
                               timera.cmpt <= I_mem_request.data;
                            when others =>
                                null;
                        end case;
                    else
                        case I_mem_request.addr(3 downto 2) is
                            when "00" =>
                                -- Read control register
                                O_mem_response.data(0) <= timera.en;
                                O_mem_response.data(4) <= timera.tcie;
                            when "01" =>
                                -- Read  status register
                                O_mem_response.data(4) <= timera.tc;
                            when "10" =>
                                -- Read counter register
                                O_mem_response.data <= timera.cntr;
                            when "11" =>
                                -- Read CMPT register
                                O_mem_response.data <= timera.cmpt;
                            when others =>
                                null;
                        end case;
                    end if;
                    O_mem_response.ready <= '1';
                end if;
            end if;

            -- If timer is enabled....
            if timera.en = '1' then
                -- If we hit the Compare Register T...
                if timera.cntr >= timera.cmpt then
                    -- Reset Counter Register
                    timera.cntr <= (others => '0');
                    -- Signal hit
                    timera.tc <= '1';
                else
                    -- Else, increment the Counter Register
                    timera.cntr <= std_logic_vector(unsigned(timera.cntr) + 1);
                end if;
            end if;
        end if;
    end process;
    
    O_irq <= timera.tcie and timera.tc;
    
end architecture rtl;