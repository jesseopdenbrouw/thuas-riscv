-- #################################################################################################
-- # bootloader.vhd - The bootloader ROM                                                           #
-- # ********************************************************************************************* #
-- # This file is part of the THUAS RISCV RV32 Project                                             #
-- # ********************************************************************************************* #
-- # BSD 3-Clause License                                                                          #
-- #                                                                                               #
-- # Copyright (c) 2023, Jesse op den Brouw. All rights reserved.                                  #
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
-- is placed in immutable onboard RAM blocks. A read takes two
-- clock cycles, for both instruction and data.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.processor_common.all;
use work.bootrom_image.all;

entity bootloader is
    generic (
          HAVE_BOOTLOADER_ROM : boolean
         );
    port (I_clk : in std_logic;
          I_areset : in std_logic;
          I_pc : in data_type;
          I_memaddress : in data_type;
          I_memsize : in memsize_type;
          I_csboot : in std_logic;
          I_stall : in std_logic;
          O_instr : out data_type;
          O_dataout : out data_type;
          O_memready : out std_logic;
          --
          O_load_misaligned_error : out std_logic
         );
end entity bootloader;

architecture rtl of bootloader is

-- The bootloader ROM
-- NOTE: the bootloader ROM is word (32 bits) size.
-- NOTE: data is in Little Endian format (as by the toolchain)
--       for half word and word entities
--       Set bootloader rom_size_bits as if it were bytes
--       default is 4 kB data
constant bootloader_size_bits : integer := 12;
constant bootloader_size : integer := 2**(bootloader_size_bits-2);
constant bootloader_length : integer := bootrom_contents'length;
signal bootrom : memory_type(0 to bootloader_size-1) := initialize_memory(bootrom_contents, bootloader_size);
begin

    gen_bootrom: if HAVE_BOOTLOADER_ROM generate

        -- Boot ROM, for both instructions and read-only data
        process (I_clk, I_areset, I_pc, I_memaddress, I_csboot, I_memsize, I_stall) is
        variable address_instr : integer range 0 to bootloader_size-1;
        variable address_data : integer range 0 to bootloader_size-1;
        variable instr_var : data_type;
        variable instr_recode : data_type;
        variable romdata_var : data_type;
        constant x : data_type := (others => 'X');
        begin
            -- Calculate addresses
            address_instr := to_integer(unsigned(I_pc(bootloader_size_bits-1 downto 2)));
            address_data := to_integer(unsigned(I_memaddress(bootloader_size_bits-1 downto 2)));

            -- Quartus will detect ROM table and uses onboard RAM
            -- Do not use reset, otherwise ROM will be created with ALMs
            if rising_edge(I_clk) then
                if I_stall = '0' then
                    instr_var := bootrom(address_instr);
                end if;
                romdata_var := bootrom(address_data);
            end if;
            
            -- Recode instruction
            O_instr <= instr_var(7 downto 0) & instr_var(15 downto 8) & instr_var(23 downto 16) & instr_var(31 downto 24);
            
            O_load_misaligned_error <= '0';
            
            -- By natural size, for data
            if I_csboot = '1' then
                if I_memsize = memsize_word and I_memaddress(1 downto 0) = "00" then
                    O_dataout <= romdata_var(7 downto 0) & romdata_var(15 downto 8) & romdata_var(23 downto 16) & romdata_var(31 downto 24);
                elsif I_memsize = memsize_halfword and I_memaddress(1 downto 0) = "00" then
                    O_dataout <= x(31 downto 16) & romdata_var(23 downto 16) & romdata_var(31 downto 24);
                elsif I_memsize = memsize_halfword and I_memaddress(1 downto 0) = "10" then
                    O_dataout <= x(31 downto 16) & romdata_var(7 downto 0) & romdata_var(15 downto 8);
                elsif I_memsize = memsize_byte then
                    case I_memaddress(1 downto 0) is
                        when "00" => O_dataout <= x(31 downto 8) & romdata_var(31 downto 24);
                        when "01" => O_dataout <= x(31 downto 8) & romdata_var(23 downto 16);
                        when "10" => O_dataout <= x(31 downto 8) & romdata_var(15 downto 8);
                        when "11" => O_dataout <= x(31 downto 8) & romdata_var(7 downto 0);
                        when others => O_dataout <= x; O_load_misaligned_error <= '1';
                    end case;
                else
                    -- Chip select, but not aligned
                    O_dataout <= x;
                    O_load_misaligned_error <= '1';
                end if;
            else
                -- No chip select, so no data
                O_dataout <= x;
            end if;
        end process;
        
        -- Generate boot ROM ready signal for reads and writes    
        process (I_clk, I_areset, I_csboot) is
        variable readready_v : std_logic;
        begin
            if I_areset = '1' then
                readready_v := '0';
            elsif rising_edge(I_clk) then
                if readready_v = '1' then
                    readready_v := '0';
                elsif I_csboot = '1' then
                    readready_v := '1';
                else
                    readready_v := '0';
                end if;
            end if;

            O_memready <= readready_v;
        end process;
        
    end generate;

    gen_bootrom_not: if not HAVE_BOOTLOADER_ROM generate
        O_load_misaligned_error <= '0';
        O_dataout <= (others => 'X');
        O_instr  <= (others => 'X');
        O_memready <= '0';
    end generate;
end architecture rtl;
