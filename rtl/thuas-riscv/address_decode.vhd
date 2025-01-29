-- #################################################################################################
-- # address_decode.vhd - Address Decoder and Data Router between the core and the memory          #
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

-- This file contains the description of address decoder and
-- data router, it interconnects the core with memory (ROM,
-- boot ROM, RAM and I/O).

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.processor_common.all;

entity address_decode is
    generic (
          -- 4 high bits of ROM address
          ROM_HIGH_NIBBLE : memory_high_nibble;
          -- 4 high bits of boot ROM address
          BOOT_HIGH_NIBBLE : memory_high_nibble;
          -- 4 high bits of RAM address
          RAM_HIGH_NIBBLE : memory_high_nibble;
          -- 4 high bits of I/O address
          IO_HIGH_NIBBLE : memory_high_nibble
         );
    port (I_clk : in std_logic;
          I_areset : in std_logic;
          -- From and to core
          I_bus_request : in bus_request_type;
          O_bus_response : out bus_response_type; 
          -- To and tp memory
          O_mem_request_rom : out mem_request_type;
          O_mem_request_boot : out mem_request_type;
          O_mem_request_ram : out mem_request_type;
          O_mem_request_io : out mem_request_type;
          I_mem_response_rom : in mem_response_type;
          I_mem_response_boot : in mem_response_type;
          I_mem_response_ram : in mem_response_type;
          I_mem_response_io : in mem_response_type
         );
end entity address_decode;

architecture rtl of address_decode is
begin

    -- Address decoder and data router (may be forward from RS1)
    process (I_bus_request, I_mem_response_rom, I_mem_response_boot, I_mem_response_ram, I_mem_response_io) is
    begin
        
        
        O_mem_request_rom.cs <= '0';
        O_mem_request_boot.cs <= '0';
        O_mem_request_ram.cs <= '0';
        O_mem_request_io.cs <= '0';

        O_mem_request_rom.wren <= '0';
        O_mem_request_boot.wren <= '0';
        O_mem_request_ram.wren <= '0';
        O_mem_request_io.wren <= '0';
        
        O_mem_request_rom.addr <= I_bus_request.addr;
        O_mem_request_rom.data <= I_bus_request.data;
        O_mem_request_rom.size <= I_bus_request.size;
        
        O_mem_request_boot.addr <= I_bus_request.addr;
        O_mem_request_boot.data <= I_bus_request.data;
        O_mem_request_boot.size <= I_bus_request.size;

        O_mem_request_ram.addr <= I_bus_request.addr;
        O_mem_request_ram.data <= I_bus_request.data;
        O_mem_request_ram.size <= I_bus_request.size;

        O_mem_request_io.addr <= I_bus_request.addr;
        O_mem_request_io.data <= I_bus_request.data;
        O_mem_request_io.size <= I_bus_request.size;
        
        O_bus_response.load_access_error <= '0';
        O_bus_response.store_access_error <= '0';
        
        O_bus_response.load_misaligned_error <= I_mem_response_rom.load_misaligned_error or
                                                I_mem_response_boot.load_misaligned_error or
                                                I_mem_response_ram.load_misaligned_error or
                                                I_mem_response_io.load_misaligned_error; 
        
        O_bus_response.store_misaligned_error <= I_mem_response_rom.store_misaligned_error or
                                                 I_mem_response_boot.store_misaligned_error or
                                                 I_mem_response_ram.store_misaligned_error or
                                                 I_mem_response_io.store_misaligned_error; 

        -- ROM @ 0xxxxxxx, 256M space, read-write
        if I_bus_request.addr(31 downto 28) = ROM_HIGH_NIBBLE then
            if I_bus_request.acc = memaccess_read or I_bus_request.acc = memaccess_write then
                O_mem_request_rom.cs <= '1';
            end if;
            if I_bus_request.acc = memaccess_write then
                O_mem_request_rom.wren <= '1';
            end if;
            O_bus_response.data <= I_mem_response_rom.data;
            O_bus_response.ready <= I_mem_response_rom.ready;
        -- Bootloader ROM @ 1xxxxxxx, 256M space, read only
        elsif I_bus_request.addr(31 downto 28) = BOOT_HIGH_NIBBLE then
            if I_bus_request.acc = memaccess_read then
                O_mem_request_boot.cs <= '1';
            end if;
            -- The boot ROM cannot be written
            if I_bus_request.acc = memaccess_write then
                O_bus_response.store_access_error <= '1';
            end if;            
            O_bus_response.data <= I_mem_response_boot.data;
            O_bus_response.ready <= I_mem_response_boot.ready;
        -- RAM @ 2xxxxxxx, 256M space, read-write
        elsif I_bus_request.addr(31 downto 28) = RAM_HIGH_NIBBLE then
            if I_bus_request.acc = memaccess_read or I_bus_request.acc = memaccess_write then
                O_mem_request_ram.cs <= '1';
            end if;
            if I_bus_request.acc = memaccess_write then
                O_mem_request_ram.wren <='1';
            end if;
            O_bus_response.data <= I_mem_response_ram.data;
            O_bus_response.ready <= I_mem_response_ram.ready;
        -- I/O @ Fxxxxxxx, 256M space, read-write
        elsif I_bus_request.addr(31 downto 28) = IO_HIGH_NIBBLE then
            if I_bus_request.acc = memaccess_read or I_bus_request.acc = memaccess_write then
                O_mem_request_io.cs <= '1';
            end if;
            if I_bus_request.acc = memaccess_write then
                O_mem_request_io.wren <='1';
            end if;
            O_bus_response.data <= I_mem_response_io.data;
            O_bus_response.ready <= I_mem_response_io.ready;
        -- Referencing unimplemented memory results in an access error
        else
            O_bus_response.ready <= '0';
            if I_bus_request.acc = memaccess_read then
                O_bus_response.load_access_error <= '1';
                -- Signal ready anyway, otherwise the bus will hang.
                O_bus_response.ready <= '1';
            end if;
            if I_bus_request.acc = memaccess_write then
                O_bus_response.store_access_error <= '1';
                -- Signal ready anyway, otherwise the bus will hang.
                O_bus_response.ready <= '1';
            end if;
            O_bus_response.data <= (others => '0');
        end if;
    end process;
    
end architecture rtl;

