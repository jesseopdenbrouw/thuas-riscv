-- #################################################################################################
-- # crc.vhd -- Cyclic Redundancy Check hardware                                                   #
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

entity crc is
    port (I_clk : in std_logic;
          I_areset : in std_logic;
          -- 
          I_mem_request : in mem_request_type;
          O_mem_response : out mem_response_type
         );
end entity crc;

architecture rtl of crc is

type crc_type is record
    sreg : data_type;
    poly : data_type;
    size : std_logic_vector(1 downto 0);
    tc : std_logic;
    data : std_logic_vector(7 downto 0);
    --
    counter : integer range 0 to 8;
    msb : std_logic;
end record;
signal crc : crc_type;

signal isword : boolean;

begin

    O_mem_response.load_misaligned_error <= '1' when I_mem_request.stb = '1' and I_mem_request.wren = '0' and (I_mem_request.size /= memsize_word or I_mem_request.addr(1 downto 0) /= "00") else '0';
    O_mem_response.store_misaligned_error <= '1' when I_mem_request.stb = '1' and I_mem_request.wren = '1' and (I_mem_request.size /= memsize_word  or I_mem_request.addr(1 downto 0) /= "00") else '0';
    isword <= I_mem_request.size = memsize_word and I_mem_request.addr(1 downto 0) = "00" ;

    process (I_clk, I_areset) is
    begin
        if I_areset = '1' then
            crc.sreg <= (others => '0');
            crc.poly <= (others => '0');
            crc.data <= (others => '0');
            crc.size <= "00";
            crc.tc <= '0';
            --
            crc.counter <= 0;
            O_mem_response.data <= all_zeros_c;
            O_mem_response.ready <= '0';
        elsif rising_edge(I_clk) then
            O_mem_response.data <= all_zeros_c;
            O_mem_response.ready <= '0';
            if I_mem_request.stb = '1' and isword then
                if I_mem_request.wren = '1' then
                    -- Write
                    case I_mem_request.addr(4 downto 2) is
                        when "000" => crc.size <= I_mem_request.data(5 downto 4);
                        when "001" => crc.tc <= I_mem_request.data(3);
                        when "010" => crc.poly <= I_mem_request.data;
                        when "011" => crc.sreg <= I_mem_request.data;
                        when "100" => crc.data <= I_mem_request.data(7 downto 0);
                                      crc.counter <= 7;
                                      crc.tc <= '0';
                        when others => null;
                    end case;
                else
                    -- Read
                    case I_mem_request.addr(4 downto 2) is
                        when "000" => O_mem_response.data(5 downto 4) <= crc.size;
                        when "001" => O_mem_response.data(3) <= crc.tc;
                        when "010" => O_mem_response.data <= crc.poly;
                        when "011" => O_mem_response.data <= crc.sreg;
                        when "100" => crc.tc <= '0';
                        when others => null;
                    end case;
                end if;
                O_mem_response.ready <= '1';
            end if;
            
            -- Galois type CRC-32 generator
            -- Figure 1 in https://www.ti.com/lit/an/spra530/spra530.pdf
            -- See https://www.allegromicro.com/-/media/files/application-notes/an296177-crc-algorithms-in-sensor-communication.pdf
            -- Pre-multiply LFSR
            
            if crc.counter > 0 then
                if crc.msb /= crc.data(7) then
                    crc.sreg <= (crc.sreg(30 downto 0) & '0') xor crc.poly;
                else
                    crc.sreg <= crc.sreg(30 downto 0) & '0';
                end if;
                crc.counter <= crc.counter - 1;
                crc.data <= crc.data(6 downto 0) & '0';
                crc.tc <= '0';
            else
                crc.tc <= '1';
            end if;
        end if;
    end process;

    crc.msb <= crc.sreg(31) when crc.size = "00" else
               crc.sreg(23) when crc.size = "01" else
               crc.sreg(15) when crc.size = "10" else
               crc.sreg(7);
              
end architecture rtl;