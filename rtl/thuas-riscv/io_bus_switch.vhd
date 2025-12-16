-- #################################################################################################
-- # io_bus_switch.vhd - Bus Multiplexer for I/O Devices                                           #
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

library work;
use work.processor_common.all;

entity io_bus_switch is
    generic (
          BUFFER_IO_RESPONSE : boolean
         );
    port (
          I_clk : in std_logic;
          I_areset : in std_logic;
          i_sreset : in std_logic;
          -- Input from address router
          I_mem_request : in mem_request_type;
          O_mem_response : out mem_response_type;
          -- Output to devices
          O_dev0_request : out mem_request_type;
          I_dev0_response : in mem_response_type;
          --
          O_dev1_request : out mem_request_type;
          I_dev1_response : in mem_response_type;
          --
          O_dev2_request : out mem_request_type;
          I_dev2_response : in mem_response_type;
          --
          O_dev3_request : out mem_request_type;
          I_dev3_response : in mem_response_type;
          --
          O_dev4_request : out mem_request_type;
          I_dev4_response : in mem_response_type;
          --
          O_dev5_request : out mem_request_type;
          I_dev5_response : in mem_response_type;
          --
          O_dev6_request : out mem_request_type;
          I_dev6_response : in mem_response_type;
          --
          O_dev7_request : out mem_request_type;
          I_dev7_response : in mem_response_type;
          --
          O_dev8_request : out mem_request_type;
          I_dev8_response : in mem_response_type;
          --
          O_dev9_request : out mem_request_type;
          I_dev9_response : in mem_response_type;
          --
          O_dev10_request : out mem_request_type;
          I_dev10_response : in mem_response_type;
          --
          O_dev11_request : out mem_request_type;
          I_dev11_response : in mem_response_type;
          --
          O_dev12_request : out mem_request_type;
          I_dev12_response : in mem_response_type;
          --
          O_dev13_request : out mem_request_type;
          I_dev13_response : in mem_response_type;
          --
          O_dev14_request : out mem_request_type;
          I_dev14_response : in mem_response_type;
          --
          O_dev15_request : out mem_request_type;
          I_dev15_response : in mem_response_type
         );
end entity io_bus_switch;

architecture rtl of io_bus_switch is

-- 256 bytes per device
constant ADDRESS_SIZE_LOG2 : integer := 8;

begin

    process (I_mem_request) is
    begin

        -- Set defaults
        O_dev0_request.addr <= I_mem_request.addr;
        O_dev0_request.size <= I_mem_request.size;
        O_dev0_request.data <= I_mem_request.data;
        O_dev0_request.wren <= I_mem_request.wren;        
        O_dev0_request.cs <= '0';
        O_dev0_request.stb <= '0';

        O_dev1_request.addr <= I_mem_request.addr;
        O_dev1_request.size <= I_mem_request.size;
        O_dev1_request.data <= I_mem_request.data;
        O_dev1_request.wren <= I_mem_request.wren;        
        O_dev1_request.cs <= '0';
        O_dev1_request.stb <= '0';
        
        O_dev2_request.addr <= I_mem_request.addr;
        O_dev2_request.size <= I_mem_request.size;
        O_dev2_request.data <= I_mem_request.data;
        O_dev2_request.wren <= I_mem_request.wren;        
        O_dev2_request.cs <= '0';
        O_dev2_request.stb <= '0';
        
        O_dev3_request.addr <= I_mem_request.addr;
        O_dev3_request.size <= I_mem_request.size;
        O_dev3_request.data <= I_mem_request.data;
        O_dev3_request.wren <= I_mem_request.wren;        
        O_dev3_request.cs <= '0';
        O_dev3_request.stb <= '0';

        O_dev4_request.addr <= I_mem_request.addr;
        O_dev4_request.size <= I_mem_request.size;
        O_dev4_request.data <= I_mem_request.data;
        O_dev4_request.wren <= I_mem_request.wren;        
        O_dev4_request.cs <= '0';
        O_dev4_request.stb <= '0';

        O_dev5_request.addr <= I_mem_request.addr;
        O_dev5_request.size <= I_mem_request.size;
        O_dev5_request.data <= I_mem_request.data;
        O_dev5_request.wren <= I_mem_request.wren;        
        O_dev5_request.cs <= '0';
        O_dev5_request.stb <= '0';

        O_dev6_request.addr <= I_mem_request.addr;
        O_dev6_request.size <= I_mem_request.size;
        O_dev6_request.data <= I_mem_request.data;
        O_dev6_request.wren <= I_mem_request.wren;        
        O_dev6_request.cs <= '0';
        O_dev6_request.stb <= '0';

        O_dev7_request.addr <= I_mem_request.addr;
        O_dev7_request.size <= I_mem_request.size;
        O_dev7_request.data <= I_mem_request.data;
        O_dev7_request.wren <= I_mem_request.wren;        
        O_dev7_request.cs <= '0';
        O_dev7_request.stb <= '0';

        O_dev8_request.addr <= I_mem_request.addr;
        O_dev8_request.size <= I_mem_request.size;
        O_dev8_request.data <= I_mem_request.data;
        O_dev8_request.wren <= I_mem_request.wren;        
        O_dev8_request.cs <= '0';
        O_dev8_request.stb <= '0';

        O_dev9_request.addr <= I_mem_request.addr;
        O_dev9_request.size <= I_mem_request.size;
        O_dev9_request.data <= I_mem_request.data;
        O_dev9_request.wren <= I_mem_request.wren;        
        O_dev9_request.cs <= '0';
        O_dev9_request.stb <= '0';

        O_dev10_request.addr <= I_mem_request.addr;
        O_dev10_request.size <= I_mem_request.size;
        O_dev10_request.data <= I_mem_request.data;
        O_dev10_request.wren <= I_mem_request.wren;        
        O_dev10_request.cs <= '0';
        O_dev10_request.stb <= '0';

        O_dev11_request.addr <= I_mem_request.addr;
        O_dev11_request.size <= I_mem_request.size;
        O_dev11_request.data <= I_mem_request.data;
        O_dev11_request.wren <= I_mem_request.wren;        
        O_dev11_request.cs <= '0';
        O_dev11_request.stb <= '0';

        O_dev12_request.addr <= I_mem_request.addr;
        O_dev12_request.size <= I_mem_request.size;
        O_dev12_request.data <= I_mem_request.data;
        O_dev12_request.wren <= I_mem_request.wren;        
        O_dev12_request.cs <= '0';
        O_dev12_request.stb <= '0';

        O_dev13_request.addr <= I_mem_request.addr;
        O_dev13_request.size <= I_mem_request.size;
        O_dev13_request.data <= I_mem_request.data;
        O_dev13_request.wren <= I_mem_request.wren;        
        O_dev13_request.cs <= '0';
        O_dev13_request.stb <= '0';

        O_dev14_request.addr <= I_mem_request.addr;
        O_dev14_request.size <= I_mem_request.size;
        O_dev14_request.data <= I_mem_request.data;
        O_dev14_request.wren <= I_mem_request.wren;        
        O_dev14_request.cs <= '0';
        O_dev14_request.stb <= '0';

        O_dev15_request.addr <= I_mem_request.addr;
        O_dev15_request.size <= I_mem_request.size;
        O_dev15_request.data <= I_mem_request.data;
        O_dev15_request.wren <= I_mem_request.wren;        
        O_dev15_request.cs <= '0';
        O_dev15_request.stb <= '0';

        -- Generate Chip SelectS - not used anymore
        if I_mem_request.cs = '1' then
            -- Make 16 groups of 2**ADDRESS_SIZE_LOG2 bytes
            case I_mem_request.addr(ADDRESS_SIZE_LOG2+3 downto ADDRESS_SIZE_LOG2) is
                when "0000" => O_dev0_request.cs <= '1';
                when "0001" => O_dev1_request.cs <= '1';
                when "0010" => O_dev2_request.cs <= '1';
                when "0011" => O_dev3_request.cs <= '1';
                when "0100" => O_dev4_request.cs <= '1';
                when "0101" => O_dev5_request.cs <= '1';
                when "0110" => O_dev6_request.cs <= '1';
                when "0111" => O_dev7_request.cs <= '1';
                when "1000" => O_dev8_request.cs <= '1';
                when "1001" => O_dev9_request.cs <= '1';
                when "1010" => O_dev10_request.cs <= '1';
                when "1011" => O_dev11_request.cs <= '1';
                when "1100" => O_dev12_request.cs <= '1';
                when "1101" => O_dev13_request.cs <= '1';
                when "1110" => O_dev14_request.cs <= '1';
                when "1111" => O_dev15_request.cs <= '1';
                when others => null;
            end case;
        end if;

        -- Generate STroBe - strobe the access to the I/O modules
        if I_mem_request.stb = '1' then
            -- Make 16 groups of 2**ADDRESS_SIZE_LOG2 bytes
            case I_mem_request.addr(ADDRESS_SIZE_LOG2+3 downto ADDRESS_SIZE_LOG2) is
                when "0000" => O_dev0_request.stb <= '1';
                when "0001" => O_dev1_request.stb <= '1';
                when "0010" => O_dev2_request.stb <= '1';
                when "0011" => O_dev3_request.stb <= '1';
                when "0100" => O_dev4_request.stb <= '1';
                when "0101" => O_dev5_request.stb <= '1';
                when "0110" => O_dev6_request.stb <= '1';
                when "0111" => O_dev7_request.stb <= '1';
                when "1000" => O_dev8_request.stb <= '1';
                when "1001" => O_dev9_request.stb <= '1';
                when "1010" => O_dev10_request.stb <= '1';
                when "1011" => O_dev11_request.stb <= '1';
                when "1100" => O_dev12_request.stb <= '1';
                when "1101" => O_dev13_request.stb <= '1';
                when "1110" => O_dev14_request.stb <= '1';
                when "1111" => O_dev15_request.stb <= '1';
                when others => null;
            end case;
        end if;
        
    end process;

    -- Generate the I/O response WITH buffering
    -- I/O read/write takes 1 clock latency now
    bufferresponsegen: if BUFFER_IO_RESPONSE generate
        process (I_clk, I_areset) is
        begin
            if I_areset = '1' then
                O_mem_response.data  <= all_zeros_c;
                O_mem_response.ready <= '0';
                O_mem_response.load_misaligned_error <= '0';
                O_mem_response.store_misaligned_error <= '0';
            elsif rising_edge(I_clk) then
                -- Fuse the responses. Max only one I/O device is responding,
                -- all non-responding devices send zero bits
                -- Fuse all response data
                O_mem_response.data <= I_dev0_response.data or
                                       I_dev1_response.data or
                                       I_dev2_response.data or
                                       I_dev3_response.data or
                                       I_dev4_response.data or
                                       I_dev5_response.data or
                                       I_dev6_response.data or
                                       I_dev7_response.data or
                                       I_dev8_response.data or
                                       I_dev9_response.data or
                                       I_dev10_response.data or
                                       I_dev11_response.data or
                                       I_dev12_response.data or
                                       I_dev13_response.data or
                                       I_dev14_response.data or
                                       I_dev15_response.data;
                                       
                -- Fuse all response readies
                O_mem_response.ready <= I_dev0_response.ready or
                                        I_dev1_response.ready or
                                        I_dev2_response.ready or
                                        I_dev3_response.ready or
                                        I_dev4_response.ready or
                                        I_dev5_response.ready or
                                        I_dev6_response.ready or
                                        I_dev7_response.ready or
                                        I_dev8_response.ready or
                                        I_dev9_response.ready or
                                        I_dev10_response.ready or
                                        I_dev11_response.ready or
                                        I_dev12_response.ready or
                                        I_dev13_response.ready or
                                        I_dev14_response.ready or
                                        I_dev15_response.ready;

                -- Fuse all response misaligneds
                O_mem_response.load_misaligned_error <= I_dev0_response.load_misaligned_error or
                                                        I_dev1_response.load_misaligned_error or
                                                        I_dev2_response.load_misaligned_error or
                                                        I_dev3_response.load_misaligned_error or
                                                        I_dev4_response.load_misaligned_error or
                                                        I_dev5_response.load_misaligned_error or
                                                        I_dev6_response.load_misaligned_error or
                                                        I_dev7_response.load_misaligned_error or
                                                        I_dev8_response.load_misaligned_error or
                                                        I_dev9_response.load_misaligned_error or
                                                        I_dev10_response.load_misaligned_error or
                                                        I_dev11_response.load_misaligned_error or
                                                        I_dev12_response.load_misaligned_error or
                                                        I_dev13_response.load_misaligned_error or
                                                        I_dev14_response.load_misaligned_error or
                                                        I_dev15_response.load_misaligned_error;
                
                O_mem_response.store_misaligned_error <= I_dev0_response.store_misaligned_error or
                                                         I_dev1_response.store_misaligned_error or
                                                         I_dev2_response.store_misaligned_error or
                                                         I_dev3_response.store_misaligned_error or
                                                         I_dev4_response.store_misaligned_error or
                                                         I_dev5_response.store_misaligned_error or
                                                         I_dev6_response.store_misaligned_error or
                                                         I_dev7_response.store_misaligned_error or
                                                         I_dev8_response.store_misaligned_error or
                                                         I_dev9_response.store_misaligned_error or
                                                         I_dev10_response.store_misaligned_error or
                                                         I_dev11_response.store_misaligned_error or
                                                         I_dev12_response.store_misaligned_error or
                                                         I_dev13_response.store_misaligned_error or
                                                         I_dev14_response.store_misaligned_error or
                                                         I_dev15_response.store_misaligned_error;
                if I_sreset = '1' then
                    O_mem_response.data  <= all_zeros_c;
                    O_mem_response.ready <= '0';
                    O_mem_response.load_misaligned_error <= '0';
                    O_mem_response.store_misaligned_error <= '0';
                end if;
            end if;
        end process;
    end generate;
    
    -- Generate the I/O response WITHOUT buffering
    -- I/O read/write has no extra latancy
    bufferresponsegen_not: if not BUFFER_IO_RESPONSE generate

        -- Fuse the responses. Max only one I/O device is responding,
        -- all non-responding devices send zero bits
        -- Fuse all response data
        O_mem_response.data <= I_dev0_response.data or
                               I_dev1_response.data or
                               I_dev2_response.data or
                               I_dev3_response.data or
                               I_dev4_response.data or
                               I_dev5_response.data or
                               I_dev6_response.data or
                               I_dev7_response.data or
                               I_dev8_response.data or
                               I_dev9_response.data or
                               I_dev10_response.data or
                               I_dev11_response.data or
                               I_dev12_response.data or
                               I_dev13_response.data or
                               I_dev14_response.data or
                               I_dev15_response.data;
                               
        -- Fuse all response readies
        O_mem_response.ready <= I_dev0_response.ready or
                                I_dev1_response.ready or
                                I_dev2_response.ready or
                                I_dev3_response.ready or
                                I_dev4_response.ready or
                                I_dev5_response.ready or
                                I_dev6_response.ready or
                                I_dev7_response.ready or
                                I_dev8_response.ready or
                                I_dev9_response.ready or
                                I_dev10_response.ready or
                                I_dev11_response.ready or
                                I_dev12_response.ready or
                                I_dev13_response.ready or
                                I_dev14_response.ready or
                                I_dev15_response.ready;

        -- Fuse all response misaligneds
        O_mem_response.load_misaligned_error <= I_dev0_response.load_misaligned_error or
                                                I_dev1_response.load_misaligned_error or
                                                I_dev2_response.load_misaligned_error or
                                                I_dev3_response.load_misaligned_error or
                                                I_dev4_response.load_misaligned_error or
                                                I_dev5_response.load_misaligned_error or
                                                I_dev6_response.load_misaligned_error or
                                                I_dev7_response.load_misaligned_error or
                                                I_dev8_response.load_misaligned_error or
                                                I_dev9_response.load_misaligned_error or
                                                I_dev10_response.load_misaligned_error or
                                                I_dev11_response.load_misaligned_error or
                                                I_dev12_response.load_misaligned_error or
                                                I_dev13_response.load_misaligned_error or
                                                I_dev14_response.load_misaligned_error or
                                                I_dev15_response.load_misaligned_error;
        
        O_mem_response.store_misaligned_error <= I_dev0_response.store_misaligned_error or
                                                 I_dev1_response.store_misaligned_error or
                                                 I_dev2_response.store_misaligned_error or
                                                 I_dev3_response.store_misaligned_error or
                                                 I_dev4_response.store_misaligned_error or
                                                 I_dev5_response.store_misaligned_error or
                                                 I_dev6_response.store_misaligned_error or
                                                 I_dev7_response.store_misaligned_error or
                                                 I_dev8_response.store_misaligned_error or
                                                 I_dev9_response.store_misaligned_error or
                                                 I_dev10_response.store_misaligned_error or
                                                 I_dev11_response.store_misaligned_error or
                                                 I_dev12_response.store_misaligned_error or
                                                 I_dev13_response.store_misaligned_error or
                                                 I_dev14_response.store_misaligned_error or
                                                 I_dev15_response.store_misaligned_error;

end generate;
end architecture rtl;