-- #################################################################################################
-- # mtime.vhd - RISC-V external timer                                                             #
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

entity mtime is
    generic (
          SYSTEM_FREQUENCY : integer;
          CLOCK_FREQUENCY : integer
         );
    port (I_clk : in std_logic;
          I_areset : in std_logic;
          -- 
          I_mem_request : in mem_request_type;
          O_mem_response : out mem_response_type;
          --
          O_irq : out std_logic;
          O_mtime : out data_type;
          O_mtimeh : out data_type
         );
end entity mtime;


architecture rtl of mtime is

type mtime_type is record
    mtime : data_type;
    mtimeh : data_type;
    mtimecmp : data_type;
    mtimecmph : data_type;
end record;

signal mtime : mtime_type;
signal isword : boolean;
-- For strobing
signal cs_sync : std_logic;

begin

    O_mem_response.load_misaligned_error <= '1' when I_mem_request.cs = '1' and I_mem_request.wren = '0' and (I_mem_request.size /= memsize_word or I_mem_request.addr(1 downto 0) /= "00") else '0';
    O_mem_response.store_misaligned_error <= '1' when I_mem_request.cs = '1' and I_mem_request.wren = '1' and (I_mem_request.size /= memsize_word  or I_mem_request.addr(1 downto 0) /= "00") else '0';
    isword <= I_mem_request.size = memsize_word and I_mem_request.addr(1 downto 0) = "00" ;

    process (I_clk, I_areset, mtime) is
    variable mtime_v : unsigned(63 downto 0);
    variable mtimecmp_v : unsigned(63 downto 0);
    variable prescaler_v : integer range 0 to SYSTEM_FREQUENCY/CLOCK_FREQUENCY-1;
    begin
        if I_areset = '1' then
            mtime_v := (others => '0');
            mtimecmp_v := (others => '0');
            prescaler_v := 0;
            O_mem_response.data <= all_zeros_c;
            O_mem_response.ready <= '0';
            cs_sync <= '0';
        elsif rising_edge(I_clk) then
            O_mem_response.data <= all_zeros_c;
            O_mem_response.ready <= '0';
            cs_sync <= I_mem_request.cs;
            -- Update system timer
            if prescaler_v = SYSTEM_FREQUENCY/CLOCK_FREQUENCY-1 then
                prescaler_v := 0;
                mtime_v := mtime_v + 1;
            else
                prescaler_v := prescaler_v + 1;
            end if;
            if I_mem_request.cs = '1' and cs_sync = '0' and isword then
                if I_mem_request.wren = '1' then
                    case I_mem_request.addr(3 downto 2) is
                        when "00" => mtime_v(31 downto 00) := unsigned(I_mem_request.data);     -- Store time (low 32 bits)
                        when "01" => mtime_v(63 downto 32) := unsigned(I_mem_request.data);     -- Store timeh (high 32 bits)
                        when "10" => mtimecmp_v(31 downto 00) := unsigned(I_mem_request.data);  -- Store compare register (low 32 bits)
                        when "11" => mtimecmp_v(63 downto 32) := unsigned(I_mem_request.data);  -- Store compare register (high 32 bits)
                        when others => null;
                    end case;
                else
                    case I_mem_request.addr(3 downto 2) is
                        when "00" => O_mem_response.data <= mtime.mtime;      -- Load time (low 32 bits)
                        when "01" => O_mem_response.data <= mtime.mtimeh;     -- Load timeh (high 32 bits)
                        when "10" => O_mem_response.data <= mtime.mtimecmp;   -- Load compare register (low 32 bits)
                        when "11" => O_mem_response.data <= mtime.mtimecmph;  -- Load compare register (high 32 bits)
                        when others => null;
                    end case;
                end if;
                O_mem_response.ready <= '1';
            end if;
        end if;
        mtime.mtime <= std_logic_vector(mtime_v(31 downto 0));
        mtime.mtimeh <= std_logic_vector(mtime_v(63 downto 32));
        mtime.mtimecmp <= std_logic_vector(mtimecmp_v(31 downto 0));
        mtime.mtimecmph <= std_logic_vector(mtimecmp_v(63 downto 32));
        -- If compare register >= time register, assert interrupt
        if mtime_v >= mtimecmp_v then
            O_irq <= '1';
        else
            O_irq <= '0';
        end if;
        O_mtime <= mtime.mtime;
        O_mtimeh <= mtime.mtimeh;
    end process;

end architecture;
