-- #################################################################################################
-- # msi.vhd - Machine-mode software interrupt                                                     #
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

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.processor_common.all;

entity msi is
    port (I_clk : in std_logic;
          I_areset : in std_logic;
          -- 
          I_mem_request : in mem_request_type;
          O_mem_response : out mem_response_type;
          --
          O_irq : out std_logic
         );
end entity msi;

architecture rtl of msi is

type msi_type is record
    trig : std_logic;
end record;

signal msi : msi_type;
signal isword : boolean;
-- For strobing
signal cs_sync : std_logic;

begin

    O_mem_response.load_misaligned_error <= '1' when I_mem_request.cs = '1' and I_mem_request.wren = '0' and (I_mem_request.size /= memsize_word or I_mem_request.addr(1 downto 0) /= "00") else '0';
    O_mem_response.store_misaligned_error <= '1' when I_mem_request.cs = '1' and I_mem_request.wren = '1' and (I_mem_request.size /= memsize_word  or I_mem_request.addr(1 downto 0) /= "00") else '0';
    isword <= I_mem_request.size = memsize_word and I_mem_request.addr(1 downto 0) = "00" ;

    process (I_clk, I_areset) is
    begin
        if I_areset = '1' then
            msi.trig <= '0';
            --
            O_mem_response.data <= all_zeros_c;
            O_mem_response.ready <= '0';
            cs_sync <= '0';
        elsif rising_edge(I_clk) then
            O_mem_response.data <= all_zeros_c;
            O_mem_response.ready <= '0';
            cs_sync <= I_mem_request.cs;
            if I_mem_request.cs = '1' and cs_sync = '0' and isword then
                if I_mem_request.wren = '1' then
                    -- Set trigger bit
                    msi.trig <= I_mem_request.data(0);
                else
                    -- Read trigger bit
                    O_mem_response.data(0) <= msi.trig;
                end if;
                O_mem_response.ready <= '1';
            end if;
        end if;
    end process;

    O_irq <= msi.trig;
    
end architecture rtl;