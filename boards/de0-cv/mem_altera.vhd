-- #################################################################################################
-- # mem_altera.vhd - Altera memory module with altsyncram IP block                                #
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
-- words only, must be natural aligned and take one clock.

-- This version uses the Altera altsyncram IP block to create
-- a single copy of the memory. The memory initialization file
-- is passed via the generic MEMORY_FILE, which must be a MIF
-- file. Set to "UNUSED" if no initialization is required.
-- The generic MEMORY_CONTENTS is ignored. The altsyncram IP
-- block can be simulated, but the contents is not visible.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Load the Altera library
library altera_mf;
use altera_mf.altera_mf_components.all;

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

-- To keep track of the strobe
signal stb_dly : std_logic;
-- Default bit contents
constant x : std_logic_vector(7 downto 0) := (others => '-');
-- Local signals
signal address_data : std_logic_vector(MEMORY_ADDRESS_BITS-1 downto 2);
signal byteena : std_logic_vector(3 downto 0);
signal datawrite : data_type;
signal address_instr : std_logic_vector(MEMORY_ADDRESS_BITS-1 downto 2);
signal dataread : data_type;
signal instruction : data_type;
signal wren_data : std_logic;

begin 

    -- Never load access error
    O_mem_response.load_access_error <= '0';

    -- Need only the upper bits for address, the lower two bits select word, halfword or byte
    address_data <= I_mem_request.addr(MEMORY_ADDRESS_BITS-1 downto 2);

    -- Calculate address for instruction fetch
    address_instr <= I_instr_request.pc(MEMORY_ADDRESS_BITS-1 downto 2);
    
    -- Create write enable for data
    wren_data <= or_reduce(byteena) and boolean_to_std_logic(MEMORY_USE_WRITE);
    
    
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
        byteena <= (others => '0');
        datawrite <= all_zeros_c;
        O_mem_response.store_misaligned_error <= '0';
        O_mem_response.store_access_error <= '1' when I_mem_request.stb = '1' and I_mem_request.wren = '1' else '0';
    end generate;

    --
    -- The memory
    --
    
    -- Use true 2-port read-write memory for data and instructions
    -- Data is both read and write, instructions is only read
    -- Contents is initialized with a MIF file, use "UNUSED" if
    -- not used (e.g. for RAM)
	altsyncram_component : altsyncram
	GENERIC MAP (
		address_reg_b                      => "CLOCK0",
		byteena_reg_b                      => "CLOCK0",
		byte_size                          => 8,
		clock_enable_input_a               => "BYPASS",
		clock_enable_input_b               => "BYPASS",
		clock_enable_output_a              => "BYPASS",
		clock_enable_output_b              => "BYPASS",
		indata_reg_b                       => "CLOCK0",
		init_file                          => MEMORY_FILE,
		intended_device_family             => "Cyclone V",
		lpm_type                           => "altsyncram",
		numwords_a                         => mem_size,
		numwords_b                         => mem_size,
		operation_mode                     => "BIDIR_DUAL_PORT",
		outdata_aclr_a                     => "NONE",
		outdata_aclr_b                     => "NONE",
		outdata_reg_a                      => "UNREGISTERED",
		outdata_reg_b                      => "UNREGISTERED",
		power_up_uninitialized             => "FALSE",
		read_during_write_mode_mixed_ports => "OLD_DATA",
		read_during_write_mode_port_a      => "NEW_DATA_NO_NBE_READ",
		read_during_write_mode_port_b      => "NEW_DATA_NO_NBE_READ",
		widthad_a                          => MEMORY_ADDRESS_BITS-2,
		widthad_b                          => MEMORY_ADDRESS_BITS-2,
		width_a                            => data_type'length,
		width_b                            => data_type'length,
		width_byteena_a                    => byteena'length,
		width_byteena_b                    => byteena'length,
		wrcontrol_wraddress_reg_b          => "CLOCK0"
	)
	PORT MAP (
		clock0                             => I_clk,
		address_a                          => address_data,
		address_b                          => address_instr,
		addressstall_a                     => '0',
		addressstall_b                     => I_instr_request.stall,
		byteena_a                          => byteena,
		byteena_b                          => "0000",
		data_a                             => datawrite,
		data_b                             => all_zeros_c,
		wren_a                             => wren_data,
		wren_b                             => '0',
		q_a                                => dataread,
		q_b                                => instruction
	);

    
    
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
        O_instr_response.instr <= instruction(7 downto 0) & instruction(15 downto 8) & instruction(23 downto 16) & instruction(31 downto 24);
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


end architecture rtl;
