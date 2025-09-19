-- #################################################################################################
-- # rom.vhd - The ROM                                                                             #
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

-- This file contains the description of the ROM. The ROM is
-- placed in mutable onboard RAM blocks and can be changed
-- by writing to it. A read takes one clock cycles for
-- instructions and two clock cycles for data. The ROM
-- contents is placed in file rom_image.vhd. ROM
-- can only be written on word boundaries when the bootloader
-- is synthesized. Instruction reads can only be on word
-- boundaries. Data read can be on byte, halfword and word
-- boundaries
-- Note: the core adds an extra buffer for memory operations.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.processor_common.all;
use work.rom_image.all;

entity rom is
    generic (
          HAVE_BOOTLOADER_ROM : boolean;
          HAVE_OCD : boolean;
          ROM_ADDRESS_BITS : integer
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
end entity rom;

architecture rtl of rom is

constant rom_size : integer := 2**(ROM_ADDRESS_BITS-2);
constant rom_length : integer := rom_contents'length;
-- The ROM itself
signal rom : memory_type(0 to rom_size-1) := initialize_memory(rom_contents, rom_size);

-- Delay strobe one clock cycle
signal stb_dly : std_logic;

begin
    
    -- ROM, for both instructions and read-write data
    process (I_clk, I_areset, I_instr_request, I_mem_request, stb_dly) is
    variable address_instr_v : integer range 0 to rom_size-1;
    variable address_data_v : integer range 0 to rom_size-1;
    variable instr_v : data_type;
    variable instr_recode_v : data_type;
    variable romdata_v : data_type;
    constant x : std_logic_vector(7 downto 0) := (others => 'X');
    begin
        -- Calculate addresses
        address_instr_v := to_integer(unsigned(I_instr_request.pc(ROM_ADDRESS_BITS-1 downto 2)));
        address_data_v := to_integer(unsigned(I_mem_request.addr(ROM_ADDRESS_BITS-1 downto 2)));
 
        -- Set store misaligned error
        if I_mem_request.stb = '1' and I_mem_request.wren = '1' and I_mem_request.size /= memsize_word then
            O_mem_response.store_misaligned_error <= '1';
        else
            O_mem_response.store_misaligned_error <= '0';
        end if;
        
        -- Quartus will detect ROM table and uses onboard RAM
        -- Do NOT use an asynchronous reset
        if rising_edge(I_clk) then
            -- Read the instruction
            if I_instr_request.stall = '0' then
                instr_v := rom(address_instr_v);
            end if;
            -- Read the data
            romdata_v := rom(address_data_v);
            if HAVE_BOOTLOADER_ROM or HAVE_OCD then
                -- Write the ROM ;-)
                if I_mem_request.stb = '1' and I_mem_request.wren = '1' and I_mem_request.size = memsize_word then
                    rom(address_data_v) <= I_mem_request.data(7 downto 0) & I_mem_request.data(15 downto 8) & 
                                           I_mem_request.data(23 downto 16) & I_mem_request.data(31 downto 24);
                end if;
            end if;
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
        -- Output recoding
        if stb_dly = '1' then
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

    O_mem_response.ready <= stb_dly or (I_mem_request.stb and I_mem_request.wren);

end architecture rtl;
