-- #################################################################################################
-- # rom.vhd - The ROM                                                                             #
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

-- This file contains the description of the ROM. The ROM is
-- placed in mutable onboard RAM blocks and can be changed
-- by writing to it. A read takes two clock cycles for
-- instructions and three clock cycles for data. The ROM
-- contents is placed in file processor_common_rom.vhd. ROM
-- can only be written on word boundaries when de bootloader
-- is synthesized. Instruction reads can only be on word
-- boundaries. Data read can be on byte, halfword and word
-- boundaries

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.processor_common.all;
use work.rom_image.all;

entity rom is
    generic (
          HAVE_BOOTLOADER_ROM : boolean;
          ROM_ADDRESS_BITS : integer;
          HAVE_FAST_STORE : boolean
         );
    port (I_clk : in std_logic;
          I_areset : in std_logic;
          I_pc : in data_type;
          I_memaddress : in data_type;
          I_memsize : in memsize_type;
          I_csrom : in std_logic;
          I_wren : in std_logic;
          I_stall : in std_logic;
          O_instr : out data_type;
          I_datain : in data_type;
          O_dataout : out data_type;
          O_memready : out std_logic;
          --
          O_load_misaligned_error : out std_logic;
          O_store_misaligned_error : out std_logic
         );
end entity rom;

architecture rtl of rom is

constant rom_size : integer := 2**(ROM_ADDRESS_BITS-2);
constant rom_length : integer := rom_contents'length;
-- The ROM itself
signal rom : memory_type(0 to rom_size-1) := initialize_memory(rom_contents, rom_size);

begin

    -- ROM, for both instructions and read-write data
    process (I_clk, I_areset, I_pc, I_memaddress, I_csrom, I_memsize, I_wren, I_datain) is
    variable address_instr_v : integer range 0 to rom_size-1;
    variable address_data_v : integer range 0 to rom_size-1;
    variable instr_v : data_type;
    variable instr_recode_v : data_type;
    variable romdata_v : data_type;
    constant x : std_logic_vector(7 downto 0) := (others => 'X');
    begin
        -- Calculate addresses
        address_instr_v := to_integer(unsigned(I_pc(ROM_ADDRESS_BITS-1 downto 2)));
        address_data_v := to_integer(unsigned(I_memaddress(ROM_ADDRESS_BITS-1 downto 2)));
 
        -- Set store misaligned error
        if I_csrom = '1' and I_wren = '1' and I_memsize /= memsize_word then
            O_store_misaligned_error <= '1';
        else
            O_store_misaligned_error <= '0';
        end if;
        
        -- Quartus will detect ROM table and uses onboard RAM
        -- Do NOT use an asynchronous reset
        if rising_edge(I_clk) then
            -- Read the instruction
            if I_stall = '0' then
                instr_v := rom(address_instr_v);
            end if;
            -- Read the data
            romdata_v := rom(address_data_v);
            if HAVE_BOOTLOADER_ROM then
                -- Write the ROM ;-)
                if I_csrom = '1' and I_wren = '1' and I_memsize = memsize_word then
                    rom(address_data_v) <= I_datain(7 downto 0) & I_datain(15 downto 8) & I_datain(23 downto 16) & I_datain(31 downto 24);
                end if;
            end if;
        end if;

        -- Recode instruction
        O_instr <= instr_v(7 downto 0) & instr_v(15 downto 8) & instr_v(23 downto 16) & instr_v(31 downto 24);
        
        O_load_misaligned_error <= '0';
        
        -- By natural size, for data
        if I_csrom = '1' and I_wren = '0' then
            if I_memsize = memsize_word and I_memaddress(1 downto 0) = "00" then
                O_dataout <= romdata_v(7 downto 0) & romdata_v(15 downto 8) & romdata_v(23 downto 16) & romdata_v(31 downto 24);
            elsif I_memsize = memsize_halfword and I_memaddress(1 downto 0) = "00" then
                O_dataout <= x & x & romdata_v(23 downto 16) & romdata_v(31 downto 24);
            elsif I_memsize = memsize_halfword and I_memaddress(1 downto 0) = "10" then
                O_dataout <= x & x & romdata_v(7 downto 0) & romdata_v(15 downto 8);
            elsif I_memsize = memsize_byte then
                case I_memaddress(1 downto 0) is
                    when "00" => O_dataout <= x & x & x & romdata_v(31 downto 24);
                    when "01" => O_dataout <= x & x & x & romdata_v(23 downto 16);
                    when "10" => O_dataout <= x & x & x & romdata_v(15 downto 8);
                    when "11" => O_dataout <= x & x & x & romdata_v(7 downto 0);
                    when others => O_dataout <= x & x & x & x; O_load_misaligned_error <= '1';
                end case;
            else
                -- Chip select, but not aligned
                O_dataout <= x & x & x & x;
                O_load_misaligned_error <= '1';
            end if;
        else
            -- No chip select, so no data
            O_dataout <= x & x & x & x;
        end if;
    end process;

    -- Generate ROM ready signal for reads and writes    
    process (I_clk, I_areset, I_csrom, I_wren) is
    variable readready_v : std_logic;
    begin
        if I_areset = '1' then
            readready_v := '0';
        elsif rising_edge(I_clk) then
            if readready_v = '1' then
                readready_v := '0';
            elsif I_csrom = '1' and I_wren = '0' then
                readready_v := '1';
            else
                readready_v := '0';
            end if;
        end if;

        -- Fuse read ready and write ready
        O_memready <= readready_v  or (I_csrom and I_wren and boolean_to_std_logic(not HAVE_FAST_STORE));
        
    end process;


end architecture rtl;
