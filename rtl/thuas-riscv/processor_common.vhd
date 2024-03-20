-- #################################################################################################
-- # processor_common.vhd - Common types and constants                                             #
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

-- This file contains the used data types and constants used in the design.
-- This file contains the component description of the `riscv` microcontroller.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package processor_common is

    -- Used data types
    -- The common data type is 32 bits wide
    subtype data_type is std_logic_vector(31 downto 0);
    
    -- For shifts with immediate operand
    subtype shift_type is std_logic_vector(4 downto 0);
    
    -- For selecting registers
    subtype reg_type is std_logic_vector(4 downto 0);
    
    -- Opcode is 7 bits in instruction
    subtype opcode_type is std_logic_vector(6 downto 0);
    
    -- Func3 extra function bits in instruction
    subtype func3_type is std_logic_vector(2 downto 0);

    -- Func7 extra function bits in instruction
    subtype func7_type is std_logic_vector(6 downto 0);
    
    -- Size of memory access
    type memsize_type is (memsize_unknown, memsize_byte, memsize_halfword, memsize_word);
    
    -- Memory access type
    type memaccess_type is (memaccess_nop, memaccess_write, memaccess_read);

    -- ALU operations
    type alu_op_type is (alu_unknown, alu_nop,
                         alu_add, alu_sub, alu_and, alu_or, alu_xor,
                         alu_slt, alu_sltu,
                         alu_addi, alu_andi, alu_ori, alu_xori,
                         alu_slti, alu_sltiu,
                         alu_sll, alu_srl, alu_sra,
                         alu_slli, alu_srli, alu_srai,
                         alu_lui, alu_auipc,
                         alu_lw, alu_lh, alu_lhu, alu_lb, alu_lbu,
                         alu_sw, alu_sh, alu_sb,
                         alu_jal_jalr,
                         alu_beq, alu_bne, alu_blt, alu_bge, alu_bltu, alu_bgeu,
                         alu_trap, alu_mret,
                         alu_multiply, alu_divrem,                 -- M standard
                         alu_csr,                                  -- Zicsr
                         alu_sh1add, alu_sh2add, alu_sh3add,       -- Zba
                         alu_bclr, alu_bclri, alu_bext, alu_bexti, -- Zbs
                         alu_binv, alu_binvi, alu_bset, alu_bseti, -- Zbs
                         alu_czeroeqz, alu_czeronez                -- Zicond
                        );
                        
    -- Control and State register operations
    type csr_op_type is (csr_nop, csr_rw, csr_rs, csr_rc, csr_rwi, csr_rsi, csr_rci);

    -- Constants for CSR addresses
    -- Common CSR registers
    constant cycle_addr : integer := 16#c00#;
    constant time_addr : integer := 16#c01#;
    constant instret_addr : integer := 16#c02#;
    constant cycleh_addr : integer := 16#c80#;
    constant timeh_addr : integer := 16#c81#;
    constant instreth_addr : integer := 16#c82#;

    -- Read only
    constant mvendorid_addr : integer := 16#f11#;
    constant marchid_addr : integer := 16#f12#;
    constant mimpid_addr : integer := 16#f13#;
    constant mhartid_addr : integer := 16#f14#;
    constant mconfigptr_addr : integer := 16#f15#;

    -- Registers for interrupts/exceptions
    constant mstatus_addr : integer := 16#300#; -- 768
    -- misa should be read/write, but here it is read only
    constant misa_addr : integer := 16#301#;
    constant mie_addr : integer := 16#304#;
    constant mtvec_addr : integer := 16#305#; -- 773
    constant mcounteren_addr : integer := 16#306#; -- 774
    constant mstatush_addr : integer := 16#310#;
    constant mscratch_addr : integer := 16#340#;
    constant mepc_addr : integer := 16#341#; -- 833
    constant mcause_addr : integer := 16#342#; -- 834
    constant mtval_addr : integer := 16#343#;
    constant mip_addr : integer := 16#344#;

    -- M mode counters
    constant mcycle_addr : integer := 16#b00#; --
    constant minstret_addr : integer := 16#b02#; --
    constant mcycleh_addr : integer := 16#b80#; --
    constant minstreth_addr : integer := 16#b82#; --
    constant mcountinhibit_addr : integer := 16#320#;

    -- M mode custom read-only
    constant mxhw_addr : integer := 16#fc0#;
    constant mxspeed_addr : integer := 16#fc1#;
    
    
    -- Constants for interrupt priority
    -- Changes here must be reflected in the interrupt handler in software
    constant INTR_PRIO_SPI1 : integer := 27;
    constant INTR_PRIO_I2C1 : integer := 26;
    constant INTR_PRIO_I2C2 : integer := 24;
    constant INTR_PRIO_UART1 : integer := 23;
    constant INTR_PRIO_TIMER2: integer := 21;
    constant INTR_PRIO_TIMER1 : integer := 20;
    constant INTR_PRIO_EXTI : integer := 18;
    -- System Timer fixed to 7, do not change
    constant INTR_PRIO_MTIME : integer := 7;
    -- System Machine Software Interrupt fixed at 3, do not change
    constant INTR_PRIO_MSI : integer := 3;
    
    -- The four most significant bits of the memeory regions
    -- select the type of memeory (ROM, boot ROM, RAM and I/O).
    -- This will create 16 regions of 256 MB each
    subtype memory_high_nibble is std_logic_vector(3 downto 0);
    
    -- 32-bit memory
    type memory_type is array (natural range <>) of data_type;
    
    -- Component description of the RISC-V SoC
    component riscv is
    generic (
          -- The frequency of the system
          SYSTEM_FREQUENCY : integer := 50000000;
          -- Frequecy of the hardware clock
          CLOCK_FREQUENCY : integer := 1000000;
          -- RISCV E (embedded) of RISCV I (full)
          HAVE_RISCV_E : boolean := false;
          -- Do we have the integer multiply/divide unit?
          HAVE_MULDIV : boolean := TRUE;
          -- Fast divide (needs more area)?
          FAST_DIVIDE : boolean := TRUE;
          -- Do we have Zba (sh?add)
          HAVE_ZBA : boolean := TRUE;
          -- Do we have Zbs (bit instructions)?
          HAVE_ZBS : boolean := TRUE;
          -- Do we have Zicond (czero.{eqz|nez})?
          HAVE_ZICOND : boolean := TRUE;
          -- Do we enable vectored mode for mtvec?
          VECTORED_MTVEC : boolean := TRUE;
          -- Do we have registers is RAM?
          HAVE_REGISTERS_IN_RAM : boolean := TRUE;
          -- Do we have a bootloader ROM?
          HAVE_BOOTLOADER_ROM : boolean := TRUE;
          -- Address width in bits, size is 2**bits
          ROM_ADDRESS_BITS : integer := 16;
          -- Address width in bits, size is 2**bits
          RAM_ADDRESS_BITS : integer := 15;
          -- 4 high bits of ROM address
          ROM_HIGH_NIBBLE : memory_high_nibble := x"0";
          -- 4 high bits of boot ROM address
          BOOT_HIGH_NIBBLE : memory_high_nibble := x"1";
          -- 4 high bits of RAM address
          RAM_HIGH_NIBBLE : memory_high_nibble := x"2";
          -- 4 high bits of I/O address
          IO_HIGH_NIBBLE : memory_high_nibble := x"F";
          -- Do we use fast store?
          HAVE_FAST_STORE : boolean := false;
          -- Do we have UART1?
          HAVE_UART1 : boolean := TRUE;
          -- Do we have SPI1?
          HAVE_SPI1 : boolean := TRUE;
          -- Do we have SPI2?
          HAVE_SPI2 : boolean := TRUE;
          -- Do we have I2C1?
          HAVE_I2C1 : boolean := TRUE;
          -- Do we have I2C2?
          HAVE_I2C2 : boolean := TRUE;
          -- Do we have TIMER1?
          HAVE_TIMER1 : boolean := TRUE;
          -- Do we have TIMER2?
          HAVE_TIMER2 : boolean := TRUE;
          -- UART1 BREAK triggers system reset
          UART1_BREAK_RESETS : boolean := false
         );
    port (I_clk : in std_logic;
          I_areset : in std_logic;
          -- GPIOA
          I_gpioapin : in data_type;
          O_gpioapout : out data_type;
          -- UART1
          I_uart1rxd : in std_logic;
          O_uart1txd : out std_logic;
          -- I2C1
          IO_i2c1scl : inout std_logic;
          IO_i2c1sda : inout std_logic;
          -- I2C2
          IO_i2c2scl : inout std_logic;
          IO_i2c2sda : inout std_logic;
          -- SPI1
          O_spi1sck : out std_logic;
          O_spi1mosi : out std_logic;
          I_spi1miso : in std_logic;
          O_spi1nss : out std_logic;
          -- SPI2
          O_spi2sck : out std_logic;
          O_spi2mosi : out std_logic;
          I_spi2miso : in std_logic;
          -- TIMER2
          O_timer2oct : out std_logic;
          IO_timer2icoca : inout std_logic;
          IO_timer2icocb : inout std_logic;
          IO_timer2icocc : inout std_logic
         );
    end component riscv;

    -- Function to get an integer based on condition is true of false
    -- Politely reused from S.T. Nolting (neorv32)
    function get_int_from_boolean(cond : boolean; val_t : integer; val_f : integer) return integer;

    -- Function to assign memeory contents    
    -- Politely reused from S.T. Nolting (neorv32)
    impure function initialize_memory(init : memory_type ; depth : integer) return memory_type;

    -- Function to change boolean into a std_logic
    function boolean_to_std_logic(condition : boolean) return std_logic;
    
    -- Function to reverse bits in std_logic_vector
    function bit_reverse(input : std_logic_vector) return std_logic_vector;

    -- Function to reduce and OR of std_logic_vector bits
    function or_reduce(input : std_logic_vector) return std_logic;

    -- Function to reduce and AND of std_logic_vector bits
    function and_reduce(input : std_logic_vector) return std_logic;
    
end package processor_common;

package body processor_common is

    -- Function to get an integer based on condition is true or false
    -- Politely reused from S.T. Nolting (neorv32)
    function get_int_from_boolean(cond : boolean; val_t : integer; val_f : integer) return integer is
    begin
        if cond = true then
            return val_t;
        else
            return val_f;
        end if;
    end function get_int_from_boolean;

    -- Function to assign memeory contents    
    -- Politely reused from S.T. Nolting (neorv32)
    impure function initialize_memory(init : memory_type; depth : integer) return memory_type is
    variable mem_v : memory_type(0 to depth-1);
    begin
        mem_v := (others => (others => '0')); -- [IMPORTANT] make sure remaining memory entries are set to zero
        if (init'length > depth) then
            return mem_v;
        end if;
        for i in 0 to init'length-1 loop -- initialize only in range of source data array
            mem_v(i) := init(i);
        end loop;
        return mem_v;
    end function initialize_memory;
    
    -- Function to change boolean into a std_logic
    function boolean_to_std_logic(condition : boolean) return std_logic is
    begin
        if condition then
            return '1';
        else
            return '0';
        end if;
    end function boolean_to_std_logic;

    -- Function to reverse bits in std_logic_vector
    function bit_reverse(input : std_logic_vector) return std_logic_vector is
    variable output : std_logic_vector(input'range);
    begin
        for i in input'range loop
            output(input'length-i-1) := input(i);
        end loop;
        return output;
    end function bit_reverse;

    -- Function to reduce and OR of std_logic_vector bits
    function or_reduce(input : std_logic_vector) return std_logic is
    variable or_v : std_logic := '0';
    begin
        for i in input'range loop
            or_v := or_v or input(i);
        end loop;
        return or_v;
    end function or_reduce;

    -- Function to reduce and AND of std_logic_vector bits
    function and_reduce(input : std_logic_vector) return std_logic is
    variable and_v : std_logic := '1';
    begin
        for i in input'range loop
            and_v := and_v and input(i);
        end loop;
        return and_v;
    end function and_reduce;
    
end package body processor_common;