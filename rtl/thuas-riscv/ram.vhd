-- #################################################################################################
-- # RAM.vhd - The RAM                                                                             #
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
-- #################################################################################################.

-- This file contains the description of a RAM block. The
-- RAM is placed in onboard RAM blocks. A write takes one
-- clock cycle, a read takes two clock cycles. Reads and
-- writes must be natural aligned.
-- Note: the core adds an extra buffer for memory operations.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.processor_common.all;

entity ram is
    generic (
          RAM_ADDRESS_BITS : integer;
          HAVE_FAST_STORE : boolean
         );
    port (I_clk : in std_logic;
          I_areset : in std_logic;
          -- From address decoder
          I_mem_request : in mem_request_type;
          -- To address decoder
          O_mem_response : out mem_response_type
         );
end entity ram;

architecture rtl of ram is

-- The RAM
-- NOTE: the RAM is 4x byte (8 bits) size, supporting
--       32-bit Big Endian storage,
--       so we have to recode to support Little Endian.
--       Set ram_size_bits as if it were bytes
constant ram_size : integer := 2**(RAM_ADDRESS_BITS-2);

-- The type of the RAM block
type ram_type is array (0 to ram_size-1) of std_logic_vector(7 downto 0);

-- The RAM as 4x 8-bit entities
signal ramhh, ramhl, ramlh, ramll : ram_type;
-- synthesis translate_off
-- Only for simulation, skip in synthesis
type ram_alt_type is array (0 to ram_size-1) of data_type;
signal ram_alt : ram_alt_type;
-- synthesis translate_on

begin 
    -- RAM + Input & output recoding
    -- The RAM is 32 bits, Big Endian, so we have to recode the inputs
    -- to support Little Endian
    process (I_clk, I_areset, I_mem_request) is
    variable address_v : integer range 0 to ram_size-1;
    constant x : std_logic_vector(7 downto 0) := (others => '-');
    variable datawrite_v : data_type;
    variable byteena_v : std_logic_vector(3 downto 0);
    variable dataout_v : data_type;
    begin
        -- Need only the upper bits for address, the lower two bits select word, halfword or byte
        address_v := to_integer(unsigned(I_mem_request.addr(RAM_ADDRESS_BITS-1 downto 2)));
        -- Data to write
        datawrite_v := I_mem_request.data;
        
        -- Clear write bytes
        byteena_v := "0000";

        -- Reset store misaligned
        O_mem_response.store_misaligned_error <= '0';
        
         -- Input recoding
        if I_mem_request.cs = '1' and I_mem_request.wren = '1' then
            case I_mem_request.size is
                -- Byte size
                when memsize_byte =>
                    case I_mem_request.addr(1 downto 0) is
                        when "00" => datawrite_v := datawrite_v(7 downto 0) & x & x & x; byteena_v := "1000";
                        when "01" => datawrite_v := x & datawrite_v(7 downto 0) & x & x; byteena_v := "0100";
                        when "10" => datawrite_v := x & x & datawrite_v(7 downto 0) & x; byteena_v := "0010";
                        when "11" => datawrite_v := x & x & x & datawrite_v(7 downto 0); byteena_v := "0001";
                        when others => datawrite_v := x & x & x & x; O_mem_response.store_misaligned_error <= '1';
                    end case;
                -- Half word size, on 2-byte boundaries
                when memsize_halfword =>
                    if I_mem_request.addr(1 downto 0) = "00" then
                        datawrite_v := datawrite_v(7 downto 0) & datawrite_v(15 downto 8) & x & x;
                        byteena_v := "1100";
                    elsif I_mem_request.addr(1 downto 0) = "10" then
                        datawrite_v := x & x & datawrite_v(7 downto 0) & datawrite_v(15 downto 8);
                        byteena_v := "0011";
                    else
                        datawrite_v :=  x & x & x & x; O_mem_response.store_misaligned_error <= '1';
                    end if;
                -- Word size, on 4-byte boundaries
                when memsize_word =>
                    if I_mem_request.addr(1 downto 0) = "00" then
                        datawrite_v := datawrite_v(7 downto 0) & datawrite_v(15 downto 8) & datawrite_v(23 downto 16) & datawrite_v(31 downto 24);
                        byteena_v := "1111";
                    else
                        datawrite_v :=  x & x & x & x; O_mem_response.store_misaligned_error <= '1';
                    end if;
                when others =>
                    datawrite_v := x & x & x & x;
            end case;
        else
            datawrite_v := x & x & x & x;
        end if;
       
        -- The RAM itself
        if rising_edge(I_clk) then
            -- Write to RAM
            -- ramll is byte y, ramlh is byte y+1, ramhl is byte y+2, ramhh is byte y+3
            if byteena_v(3) = '1' then
                ramhh(address_v) <= datawrite_v(31 downto 24);
            end if;
            if byteena_v(2) = '1' then
                ramhl(address_v) <= datawrite_v(23 downto 16);
            end if;
            if byteena_v(1) = '1' then
                ramlh(address_v) <= datawrite_v(15 downto 8);
            end if;
            if byteena_v(0) = '1' then
                ramll(address_v) <= datawrite_v(7 downto 0);
            end if;
            -- Read from RAM, in Big Endian format (31-24, 23-16, 15-8, 7-0)
            dataout_v := ramhh(address_v) & ramhl(address_v) & ramlh(address_v) & ramll(address_v);
        end if;

        O_mem_response.load_misaligned_error <= '0';
        -- Output recoding
        if I_mem_request.cs = '1' and I_mem_request.wren = '0' then
            case I_mem_request.size is
                -- Byte size
                when memsize_byte =>
                    case I_mem_request.addr(1 downto 0) is
                        when "00" => O_mem_response.data <= x & x & x & dataout_v(31 downto 24);
                        when "01" => O_mem_response.data <= x & x & x & dataout_v(23 downto 16);
                        when "10" => O_mem_response.data <= x & x & x & dataout_v(15 downto 8);
                        when "11" => O_mem_response.data <= x & x & x & dataout_v(7 downto 0);
                        when others => O_mem_response.data <= x & x & x & x; O_mem_response.load_misaligned_error <= '1';
                    end case;
                -- Half word size
                when memsize_halfword =>
                    if I_mem_request.addr(1 downto 0) = "00" then
                        O_mem_response.data <= x & x & dataout_v(23 downto 16) & dataout_v(31 downto 24);
                    elsif I_mem_request.addr(1 downto 0) = "10" then
                        O_mem_response.data <= x & x & dataout_v(7 downto 0) & dataout_v(15 downto 8);
                    else
                        O_mem_response.data <= x & x & x & x; O_mem_response.load_misaligned_error <= '1';
                    end if;
                -- Word size
                when memsize_word =>
                    if I_mem_request.addr(1 downto 0) = "00" then
                        O_mem_response.data <= dataout_v(7 downto 0) & dataout_v(15 downto 8) & dataout_v(23 downto 16) & dataout_v(31 downto 24);
                    else
                        O_mem_response.data <= x & x & x & x; O_mem_response.load_misaligned_error <= '1';
                    end if;
                when others =>
                    O_mem_response.data <= x & x & x & x;
            end case;
        else
            O_mem_response.data <= x & x & x & x;
        end if;
        
    end process;

    -- Generate RAM ready signal for reads and writes    
    process (I_clk, I_areset, I_mem_request) is
    variable readready_v : std_logic;
    begin
        if I_areset = '1' then
            readready_v := '0';
        elsif rising_edge(I_clk) then
            if readready_v = '1' then
                readready_v := '0';
            elsif I_mem_request.cs = '1' and I_mem_request.wren = '0' then
                readready_v := '1';
            else
                readready_v := '0';
            end if;
        end if;

        -- Fuse read ready and write ready
        O_mem_response.ready <= readready_v  or (I_mem_request.cs and I_mem_request.wren and boolean_to_std_logic(not HAVE_FAST_STORE));

    end process;

    
    -- For simulation only, now it can be used in the simulator.
    -- synthesis translate_off
    process (ramll, ramlh, ramhl, ramhh) is
    begin
        for i in 0 to ram_size-1 loop
            ram_alt(i) <= ramll(i) & ramlh(i) & ramhl(i) & ramhh(i);
        end loop;
    end process;
    -- synthesis translate_on

end architecture rtl;
