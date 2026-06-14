-- #################################################################################################
-- # mem.vhd - Generic memory module                                                               #
-- # ********************************************************************************************* #
-- # This file is part of the THUAS RISCV RV32 Project                                             #
-- # ********************************************************************************************* #
-- # BSD 3-Clause License                                                                          #
-- #                                                                                               #
-- # Copyright (c) 2026, Jesse op den Brouw. All rights reserved.                                  #
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

-- This file contains the description of a memory block. The
-- memory is placed in onboard RAM blocks. A write takes one
-- clock cycle, a read takes two clock cycles. Reads and
-- writes must be natural aligned. Instructions reads in 
-- words only and must be natural aligned and take one clock.

-- This description is written in a device agnostic way. It is
-- up to the syntesizer to allocate onboard RAM blocks. The
-- memory may be initialized with a contents via the generic
-- MEMORY_CONTENTS. which is an array of 32-bit words. The
-- generic MEMORY_FILE is ignored. The contents if the RAM
-- is visible in the simulator.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.processor_common.all;

entity mem is
    generic (
          -- Number of address bits (byte oriented)
          MEMORY_ADDRESS_BITS : integer;
          -- Is the memory used for instructions?
          MEMORY_USE_INSTRUCTIONS : boolean;
          -- Is the memory writable?
          MEMORY_USE_WRITE : boolean;
          -- The contents of the memory
          MEMORY_CONTENTS : memory_type;
          -- The default contents of the memory bits
          MEMORY_DEFAULT : std_logic;
          -- The memory file supplied
          MEMORY_FILE : string
         );
    port (I_clk : in std_logic;
          I_areset : in std_logic;
          I_sreset : in std_logic;
          -- To fetch an instruction
          I_instr_request : in instr_request_type;
          O_instr_response : out instr_response2_type;
          -- From address decoder
          I_mem_request : in mem_request_type;
          O_mem_response : out mem_response_type
         );
end entity mem;

architecture rtl of mem is

-- The memory size in words
constant mem_size : integer := 2**(MEMORY_ADDRESS_BITS-2);

-- Memory is in 4 bytes, load with default contents
signal memhh : memorybyte_type(0 to mem_size-1) := initialize_memorybyte(MEMORY_CONTENTS, mem_size, 3, MEMORY_DEFAULT);
signal memhl : memorybyte_type(0 to mem_size-1) := initialize_memorybyte(MEMORY_CONTENTS, mem_size, 2, MEMORY_DEFAULT);
signal memlh : memorybyte_type(0 to mem_size-1) := initialize_memorybyte(MEMORY_CONTENTS, mem_size, 1, MEMORY_DEFAULT);
signal memll : memorybyte_type(0 to mem_size-1) := initialize_memorybyte(MEMORY_CONTENTS, mem_size, 0, MEMORY_DEFAULT);

-- synthesis translate_off
-- Only for simulation, skip in synthesis
type mem_alt_type is array (0 to mem_size-1) of data_type;
signal mem_alt : mem_alt_type;
-- synthesis translate_on

-- To keep track of the strobe
signal stb_dly : std_logic;
-- Default bit contents
constant x : std_logic_vector(7 downto 0) := (others => '-');
-- Local signals
signal address_data : integer range 0 to mem_size-1;
signal byteena : std_logic_vector(3 downto 0);
signal datawrite : data_type;
signal address_instr : integer range 0 to mem_size-1;
signal dataread : data_type;

begin 

    -- Never load access error
    O_mem_response.load_access_error <= '0';

    -- Need only the upper bits for address, the lower two bits select word, halfword or byte
    address_data <= to_integer(unsigned(I_mem_request.addr(MEMORY_ADDRESS_BITS-1 downto 2)));

    -- Calculate address for instruction fetch
    addressgen : if MEMORY_USE_INSTRUCTIONS generate
        address_instr <= to_integer(unsigned(I_instr_request.pc(MEMORY_ADDRESS_BITS-1 downto 2)));
    end generate;
    

    --
    -- Input recoding for writes
    --
    
    -- Memory is writable
    writegen : if MEMORY_USE_WRITE generate
        O_mem_response.store_access_error <= '0';

        -- Input recoding
        process (I_mem_request) is
        variable datawrite_v : data_type;
        variable byteena_v : std_logic_vector(3 downto 0);
        begin
            -- Data to write
            datawrite_v := I_mem_request.data;
            
            -- Clear write bytes
            byteena_v := "0000";

            -- Reset store misaligned
            O_mem_response.store_misaligned_error <= '0';
            
             -- Input recoding
            if I_mem_request.stb = '1' and I_mem_request.wren = '1' then
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
            byteena <= byteena_v;
            datawrite <= datawrite_v;
        end process;
    end generate;
    writegen_not : if not MEMORY_USE_WRITE generate
        --byteena <= (others => '0');
        --datawrite <= all_zeros_c;
        O_mem_response.store_misaligned_error <= '0';
        O_mem_response.store_access_error <= '1' when I_mem_request.stb = '1' and I_mem_request.wren = '1' else '0';
    end generate;

    --
    -- The memory
    --
    
    -- Memory is writable
    writegenm : if MEMORY_USE_WRITE generate
        -- Memory write
        process (I_clk) is
        begin
            -- The memory itself
            if rising_edge(I_clk) then
                -- Write to memory
                -- memll is byte y, memlh is byte y+1, mehl is byte y+2, memhh is byte y+3
                if byteena(3) = '1' then
                    memhh(address_data) <= datawrite(31 downto 24);
                end if;
                if byteena(2) = '1' then
                    memhl(address_data) <= datawrite(23 downto 16);
                end if;
                if byteena(1) = '1' then
                    memlh(address_data) <= datawrite(15 downto 8);
                end if;
                if byteena(0) = '1' then
                    memll(address_data) <= datawrite(7 downto 0);
                end if;
            end if;
        end process;
    end generate;

    -- Memory is always readable
    process (I_clk) is
    begin
        if rising_edge(I_clk) then
            -- Read from memory, in Big Endian format (31-24, 23-16, 15-8, 7-0)
            dataread <= memhh(address_data) & memhl(address_data) & memlh(address_data) & memll(address_data);
        end if;
    end process;
    
    
    --
    --  Memory read and recoding
    --
    
    -- Memory is always readable (e.g. read-only constants)
    process (stb_dly, I_mem_request, dataread) is
    variable dataout_v : data_type;
    begin
        O_mem_response.load_misaligned_error <= '0';
        
        dataout_v := dataread;
        
        -- Output recoding
        if stb_dly = '1' then
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
                -- Memory size unknown
                when others =>
                    O_mem_response.data <= x & x & x & x;
            end case;
        else
            O_mem_response.data <= x & x & x & x;
        end if;
        
    end process;

    O_mem_response.ready <= stb_dly or (I_mem_request.stb and I_mem_request.wren);


    --
    -- Instruction reads
    --

    -- Use the memory for instructions
    instrgen : if MEMORY_USE_INSTRUCTIONS generate
        process (I_clk) is
        variable instr_v : data_type;
        begin
            if rising_edge(I_clk) then
                -- If we don't have to stall...
                if I_instr_request.stall = '0' then
                    instr_v := memhh(address_instr) & memhl(address_instr) & memlh(address_instr) & memll(address_instr);
                end if;
            end if;
            -- Recode instruction
            O_instr_response.instr <= instr_v(7 downto 0) & instr_v(15 downto 8) & instr_v(23 downto 16) & instr_v(31 downto 24);
        end process;
    end generate;
    instrgen_not : if not MEMORY_USE_INSTRUCTIONS generate
        O_instr_response.instr <= all_zeros_c;
    end generate;


    -- Delay the strobe, for read, a read needs two cycles.
    -- First the address is set and in the next cycle the
    -- data is read.
    process (I_clk, I_areset) is
    begin
        if I_areset = '1' then
            stb_dly <= '0';
        elsif rising_edge(I_clk) then
            if I_sreset = '1' then
                stb_dly <= '0';
            else
                stb_dly <= I_mem_request.stb and not I_mem_request.wren;
            end if;
        end if;
    end process;
    

    -- For simulation only, now it can be used in the simulator.
    -- synthesis translate_off
    process (memll, memlh, memhl, memhh) is
    begin
        for i in 0 to mem_size-1 loop
            mem_alt(i) <= memll(i) & memlh(i) & memhl(i) & memhh(i);
        end loop;
    end process;
    -- synthesis translate_on

end architecture rtl;
