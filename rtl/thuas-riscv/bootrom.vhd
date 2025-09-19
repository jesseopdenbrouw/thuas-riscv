-- #################################################################################################
-- # bootrom.vhd - The bootloader ROM                                                              #
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

-- This file contains the description of the bootloader ROM. The ROM
-- is placed in immutable onboard RAM blocks. A read takes one
-- clock cycle, for both instruction and data.
-- Note: the core adds an extra buffer for memory operations.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.processor_common.all;
use work.bootrom_image.all;

entity bootrom is
    generic (
          HAVE_BOOTLOADER_ROM : boolean
         );
    port (I_clk : in std_logic;
          I_areset : in std_logic;
          -- To fetch an instruction
          I_instr_request : in instr_request_type;
          O_instr_response : out instr_response2_type;
          -- From address decoder
          I_mem_request : in mem_request_type;
          O_mem_response : out mem_response_type
         );
end entity bootrom;

architecture rtl of bootrom is

-- The boot ROM
-- NOTE: the boot ROM is word (32 bits) size.
-- NOTE: data is in Little Endian format (as by the toolchain)
--       for half word and word entities
--       Set bootloader rom_size_bits as if it were bytes
--       default is 4 kB data
constant bootrom_size_bits : integer := 12;
constant bootrom_size : integer := 2**(bootrom_size_bits-2);
constant bootrom_length : integer := bootrom_contents'length;
signal bootrom : memory_type(0 to bootrom_size-1) := initialize_memory(bootrom_contents, bootrom_size);

-- Delay strobe one clock cycle
signal stb_dly : std_logic;

begin

    bootromgen : if HAVE_BOOTLOADER_ROM generate

        -- Boot ROM, for both instructions and read-only data
        process (I_clk, I_areset, I_instr_request, I_mem_request) is
        variable address_instr_v : integer range 0 to bootrom_size-1;
        variable address_data_v : integer range 0 to bootrom_size-1;
        variable instr_v : data_type;
        variable romdata_v : data_type;
        constant x : std_logic_vector(7 downto 0) := (others => 'X');

        begin
            -- Calculate addresses
            address_instr_v := to_integer(unsigned(I_instr_request.pc(bootrom_size_bits-1 downto 2)));
            address_data_v := to_integer(unsigned(I_mem_request.addr(bootrom_size_bits-1 downto 2)));

            -- Quartus will detect ROM table and uses onboard RAM
            -- Do not use reset, otherwise ROM will be created with ALMs
            if rising_edge(I_clk) then
                if I_instr_request.stall = '0' then
                    instr_v := bootrom(address_instr_v);
                end if;
                romdata_v := bootrom(address_data_v);
            end if;

            -- Recode instruction
            O_instr_response.instr <= instr_v(7 downto 0) & instr_v(15 downto 8) & instr_v(23 downto 16) & instr_v(31 downto 24);

            -- Delay the strobe, for read, a read needs two cycles.
            -- First the address is set and in the next cycle the
            -- data is read.
            if I_areset = '1' then
                stb_dly <= '0';
            elsif rising_edge(I_clk) then
                stb_dly <= I_mem_request.stb and not I_mem_request.wren;
            end if;
            
            O_mem_response.load_misaligned_error <= '0';
            O_mem_response.store_misaligned_error <= '0';

            -- Output recoding
            if stb_dly = '1' and I_mem_request.wren = '0' then
                case I_mem_request.size is
                    -- Byte size
                    when memsize_byte =>
                        case I_mem_request.addr(1 downto 0) is
                            when "00" => O_mem_response.data <= x & x & x & romdata_v(31 downto 24);
                            when "01" => O_mem_response.data <= x & x & x & romdata_v(23 downto 16);
                            when "10" => O_mem_response.data <= x & x & x & romdata_v(15 downto 8);
                            when "11" => O_mem_response.data <= x & x & x & romdata_v(7 downto 0);
                            when others => O_mem_response.data <= x & x & x & x; O_mem_response.load_misaligned_error <= '1';
                        end case;
                    -- Half word size
                    when memsize_halfword =>
                        if I_mem_request.addr(1 downto 0) = "00" then
                            O_mem_response.data <= x & x & romdata_v(23 downto 16) & romdata_v(31 downto 24);
                        elsif I_mem_request.addr(1 downto 0) = "10" then
                            O_mem_response.data <= x & x & romdata_v(7 downto 0) & romdata_v(15 downto 8);
                        else
                            O_mem_response.data <= x & x & x & x; O_mem_response.load_misaligned_error <= '1';
                        end if;
                    -- Word size
                    when memsize_word =>
                        if I_mem_request.addr(1 downto 0) = "00" then
                            O_mem_response.data <= romdata_v(7 downto 0) & romdata_v(15 downto 8) & romdata_v(23 downto 16) & romdata_v(31 downto 24);
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
        
        O_mem_response.ready <= stb_dly;
        
    end generate;

    gen_bootrom_not: if not HAVE_BOOTLOADER_ROM generate
        O_instr_response.instr  <= (others => 'X');
        O_mem_response.data <= (others => 'X');
        O_mem_response.ready <= '0';
        O_mem_response.load_misaligned_error <= '0';
        O_mem_response.store_misaligned_error <= '0';
    end generate;
end architecture rtl;
