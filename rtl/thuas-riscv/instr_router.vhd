-- #################################################################################################
-- # instr_router.vhd - Router for instructions between core, ROM and bootloader ROM               #
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

-- The instruction router routes instructions from the main ROM
-- and the boot ROM.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.processor_common.all;

entity instr_router is
    generic (
          HAVE_BOOTLOADER_ROM : boolean;
          ROM_HIGH_NIBBLE : memory_high_nibble;
          BOOT_HIGH_NIBBLE : memory_high_nibble
         );
    port (         
          -- Instruction request from core
          I_instr_request : in instr_request_type;
          O_instr_response : out instr_response_type;
          -- To/from ROM
          O_instr_request_rom : out instr_request_type;
          I_instr_response_rom : in instr_response2_type;
          -- To/from boot ROM
          O_instr_request_boot : out instr_request_type;
          I_instr_response_boot : in instr_response2_type
         );
end entity instr_router;

architecture rtl of instr_router is
begin

    O_instr_request_rom <= I_instr_request;
    O_instr_request_boot <= I_instr_request;
    
    process (I_instr_request, I_instr_response_rom, I_instr_response_boot) is
    begin
        O_instr_response.instr_access_error <= '0';
        
        -- If the ROM is addressed, return instruction from ROM
        if I_instr_request.pc(31 downto 28) = ROM_HIGH_NIBBLE then
            O_instr_response.instr <= I_instr_response_rom.instr;
        -- If the boot ROM is addressed, return instruction from boot ROM
        elsif I_instr_request.pc(31 downto 28) = BOOT_HIGH_NIBBLE and HAVE_BOOTLOADER_ROM then
            O_instr_response.instr <= I_instr_response_boot.instr;
        else
            O_instr_response.instr <= (others => '-');
            O_instr_response.instr_access_error <= '1';
        end if;
    end process;
    
end architecture;