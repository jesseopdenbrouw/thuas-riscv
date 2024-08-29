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

    -- Hardware version, BCD encoded
    constant HW_VERSION : integer := 16#01_00_00_01#;
    
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

    -- The four most significant bits of the memeory regions
    -- select the type of memeory (ROM, boot ROM, RAM and I/O).
    -- This will create 16 regions of 256 MB each
    subtype memory_high_nibble is std_logic_vector(3 downto 0);
    
    -- 32-bit memory
    type memory_type is array (natural range <>) of data_type;
    
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
    
    -- Access from core to address decoder
    type bus_request_type is record
        acc : memaccess_type;
        size : memsize_type;
        addr : data_type;
        data : data_type;
    end record;
    -- Response from address decoder to core
    type bus_response_type is record
        data : data_type;
        ready : std_logic;
        load_access_error : std_logic;
        store_access_error : std_logic;
        load_misaligned_error : std_logic;
        store_misaligned_error : std_logic;
    end record;
    
    -- Access from address decoder to memory
    type mem_request_type is record
        size : memsize_type;
        addr : data_type;
        data : data_type;
        cs : std_logic;
        wren : std_logic;
    end record;
    -- Response from memory to address decoder
    type mem_response_type is record
        data : data_type;
        ready : std_logic;
        load_misaligned_error : std_logic;
        store_misaligned_error : std_logic;
    end record;
    
    -- Request instruction from memory
    type instr_request_type is record
        pc : data_type;
        stall : std_logic;
    end record;
    -- Response instruction to core
    type instr_response_type is record
        instr : data_type;
        instr_access_error : std_logic;
    end record;
    -- Response instruction to instruction router
    type instr_response2_type is record
        instr : data_type;
    end record;

    -- DMI request --
    type dmi_request_type is record
        addr : std_logic_vector(06 downto 0);
        data : std_logic_vector(31 downto 0);
        op   : std_logic_vector(01 downto 0);
    end record;

    -- DMI response --
    type dmi_response_type is record
        data : std_logic_vector(31 downto 0);
        ack  : std_logic;
    end record;

    -- DMI request operation --
    constant dmi_req_nop_c : std_logic_vector(1 downto 0) := "00"; -- no operation
    constant dmi_req_rd_c  : std_logic_vector(1 downto 0) := "01"; -- read access
    constant dmi_req_wr_c  : std_logic_vector(1 downto 0) := "10"; -- write access

    -- DM to core data request
    type dm_core_data_request_type is record
        address  : std_logic_vector(31 downto 0);
        readgpr  : std_logic;
        readcsr  : std_logic;
        readmem  : std_logic;
        writegpr : std_logic;
        writecsr : std_logic;
        writemem : std_logic;
        size     : std_logic_vector(1 downto 0); -- only for mem access
        data     : std_logic_vector(31 downto 0);
    end record;

    -- Core to DM data response
    type dm_core_data_response_type is record
        data     : std_logic_vector(31 downto 0);
        excep    : std_logic;
        buserr   : std_logic;
        ack      : std_logic;
    end record;
    
    -- CPU state change request
    type cpu_statechange_request_type is record
        reset  : std_logic;
        halt   : std_logic;
        resume : std_logic;
    end record;
    
    -- CPU state change response
    type cpu_statechange_response_type is record
        reset  : std_logic;
        halt   : std_logic;
        resume : std_logic;
    end record;

    -- Constants
    constant all_zeros_c : data_type := (others => '0');
    constant all_ones_c : data_type := (others => '1');

    -- Constants for CSR addresses
    -- Common CSR registers
    constant cycle_addr : integer := 16#c00#;
    constant time_addr : integer := 16#c01#;
    constant instret_addr : integer := 16#c02#;
    constant cycleh_addr : integer := 16#c80#;
    constant timeh_addr : integer := 16#c81#;
    constant instreth_addr : integer := 16#c82#;

    constant hpmcounter3_addr : integer := 16#c03#; --
    constant hpmcounter4_addr : integer := 16#c04#; --
    constant hpmcounter5_addr : integer := 16#c05#; --
    constant hpmcounter6_addr : integer := 16#c06#; --
    constant hpmcounter7_addr : integer := 16#c07#; --
    constant hpmcounter8_addr : integer := 16#c08#; --
    constant hpmcounter9_addr : integer := 16#c09#; --
    constant hpmcounter10_addr : integer := 16#c0a#; --
    constant hpmcounter11_addr : integer := 16#c0b#; --
    constant hpmcounter12_addr : integer := 16#c0c#; --
    constant hpmcounter13_addr : integer := 16#c0d#; --
    constant hpmcounter14_addr : integer := 16#c0e#; --
    constant hpmcounter15_addr : integer := 16#c0f#; --
    constant hpmcounter16_addr : integer := 16#c10#; --
    constant hpmcounter17_addr : integer := 16#c11#; --
    constant hpmcounter18_addr : integer := 16#c12#; --
    constant hpmcounter19_addr : integer := 16#c13#; --
    constant hpmcounter20_addr : integer := 16#c14#; --
    constant hpmcounter21_addr : integer := 16#c15#; --
    constant hpmcounter22_addr : integer := 16#c16#; --
    constant hpmcounter23_addr : integer := 16#c17#; --
    constant hpmcounter24_addr : integer := 16#c18#; --
    constant hpmcounter25_addr : integer := 16#c19#; --
    constant hpmcounter26_addr : integer := 16#c1a#; --
    constant hpmcounter27_addr : integer := 16#c1b#; --
    constant hpmcounter28_addr : integer := 16#c1c#; --
    constant hpmcounter29_addr : integer := 16#c1d#; --
    constant hpmcounter30_addr : integer := 16#c1e#; --
    constant hpmcounter31_addr : integer := 16#c1f#; --

    constant hpmcounter3h_addr : integer := 16#c83#; --
    constant hpmcounter4h_addr : integer := 16#c84#; --
    constant hpmcounter5h_addr : integer := 16#c85#; --
    constant hpmcounter6h_addr : integer := 16#c86#; --
    constant hpmcounter7h_addr : integer := 16#c87#; --
    constant hpmcounter8h_addr : integer := 16#c88#; --
    constant hpmcounter9h_addr : integer := 16#c89#; --
    constant hpmcounter10h_addr : integer := 16#c8a#; --
    constant hpmcounter11h_addr : integer := 16#c8b#; --
    constant hpmcounter12h_addr : integer := 16#c8c#; --
    constant hpmcounter13h_addr : integer := 16#c8d#; --
    constant hpmcounter14h_addr : integer := 16#c8e#; --
    constant hpmcounter15h_addr : integer := 16#c8f#; --
    constant hpmcounter16h_addr : integer := 16#c90#; --
    constant hpmcounter17h_addr : integer := 16#c91#; --
    constant hpmcounter18h_addr : integer := 16#c92#; --
    constant hpmcounter19h_addr : integer := 16#c93#; --
    constant hpmcounter20h_addr : integer := 16#c94#; --
    constant hpmcounter21h_addr : integer := 16#c95#; --
    constant hpmcounter22h_addr : integer := 16#c96#; --
    constant hpmcounter23h_addr : integer := 16#c97#; --
    constant hpmcounter24h_addr : integer := 16#c98#; --
    constant hpmcounter25h_addr : integer := 16#c99#; --
    constant hpmcounter26h_addr : integer := 16#c9a#; --
    constant hpmcounter27h_addr : integer := 16#c9b#; --
    constant hpmcounter28h_addr : integer := 16#c9c#; --
    constant hpmcounter29h_addr : integer := 16#c9d#; --
    constant hpmcounter30h_addr : integer := 16#c9e#; --
    constant hpmcounter31h_addr : integer := 16#c9f#; --

    -- Read only
    constant mvendorid_addr : integer := 16#f11#;
    constant marchid_addr : integer := 16#f12#;
    constant mimpid_addr : integer := 16#f13#;
    constant mhartid_addr : integer := 16#f14#;
    constant mconfigptr_addr : integer := 16#f15#;

    -- Registers for interrupts/exceptions
    constant mstatus_addr : integer := 16#300#; -- 768
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
    -- mtime does not exist
    constant minstret_addr : integer := 16#b02#; --
    constant mhpmcounter3_addr : integer := 16#b03#; --
    constant mhpmcounter4_addr : integer := 16#b04#; --
    constant mhpmcounter5_addr : integer := 16#b05#; --
    constant mhpmcounter6_addr : integer := 16#b06#; --
    constant mhpmcounter7_addr : integer := 16#b07#; --
    constant mhpmcounter8_addr : integer := 16#b08#; --
    constant mhpmcounter9_addr : integer := 16#b09#; --
    constant mhpmcounter10_addr : integer := 16#b0a#; --
    constant mhpmcounter11_addr : integer := 16#b0b#; --
    constant mhpmcounter12_addr : integer := 16#b0c#; --
    constant mhpmcounter13_addr : integer := 16#b0d#; --
    constant mhpmcounter14_addr : integer := 16#b0e#; --
    constant mhpmcounter15_addr : integer := 16#b0f#; --
    constant mhpmcounter16_addr : integer := 16#b10#; --
    constant mhpmcounter17_addr : integer := 16#b11#; --
    constant mhpmcounter18_addr : integer := 16#b12#; --
    constant mhpmcounter19_addr : integer := 16#b13#; --
    constant mhpmcounter20_addr : integer := 16#b14#; --
    constant mhpmcounter21_addr : integer := 16#b15#; --
    constant mhpmcounter22_addr : integer := 16#b16#; --
    constant mhpmcounter23_addr : integer := 16#b17#; --
    constant mhpmcounter24_addr : integer := 16#b18#; --
    constant mhpmcounter25_addr : integer := 16#b19#; --
    constant mhpmcounter26_addr : integer := 16#b1a#; --
    constant mhpmcounter27_addr : integer := 16#b1b#; --
    constant mhpmcounter28_addr : integer := 16#b1c#; --
    constant mhpmcounter29_addr : integer := 16#b1d#; --
    constant mhpmcounter30_addr : integer := 16#b1e#; --
    constant mhpmcounter31_addr : integer := 16#b1f#; --

    constant mcycleh_addr : integer := 16#b80#; --
    constant minstreth_addr : integer := 16#b82#; --
    constant mhpmcounter3h_addr : integer := 16#b83#; --
    constant mhpmcounter4h_addr : integer := 16#b84#; --
    constant mhpmcounter5h_addr : integer := 16#b85#; --
    constant mhpmcounter6h_addr : integer := 16#b86#; --
    constant mhpmcounter7h_addr : integer := 16#b87#; --
    constant mhpmcounter8h_addr : integer := 16#b88#; --
    constant mhpmcounter9h_addr : integer := 16#b89#; --
    constant mhpmcounter10h_addr : integer := 16#b8a#; --
    constant mhpmcounter11h_addr : integer := 16#b8b#; --
    constant mhpmcounter12h_addr : integer := 16#b8c#; --
    constant mhpmcounter13h_addr : integer := 16#b8d#; --
    constant mhpmcounter14h_addr : integer := 16#b8e#; --
    constant mhpmcounter15h_addr : integer := 16#b8f#; --
    constant mhpmcounter16h_addr : integer := 16#b90#; --
    constant mhpmcounter17h_addr : integer := 16#b91#; --
    constant mhpmcounter18h_addr : integer := 16#b92#; --
    constant mhpmcounter19h_addr : integer := 16#b93#; --
    constant mhpmcounter20h_addr : integer := 16#b94#; --
    constant mhpmcounter21h_addr : integer := 16#b95#; --
    constant mhpmcounter22h_addr : integer := 16#b96#; --
    constant mhpmcounter23h_addr : integer := 16#b97#; --
    constant mhpmcounter24h_addr : integer := 16#b98#; --
    constant mhpmcounter25h_addr : integer := 16#b99#; --
    constant mhpmcounter26h_addr : integer := 16#b9a#; --
    constant mhpmcounter27h_addr : integer := 16#b9b#; --
    constant mhpmcounter28h_addr : integer := 16#b9c#; --
    constant mhpmcounter29h_addr : integer := 16#b9d#; --
    constant mhpmcounter30h_addr : integer := 16#b9e#; --
    constant mhpmcounter31h_addr : integer := 16#b9f#; --

    constant mcountinhibit_addr : integer := 16#320#; --
    constant mhpmevent3_addr : integer := 16#323#; --
    constant mhpmevent4_addr : integer := 16#324#; --
    constant mhpmevent5_addr : integer := 16#325#; --
    constant mhpmevent6_addr : integer := 16#326#; --
    constant mhpmevent7_addr : integer := 16#327#; --
    constant mhpmevent8_addr : integer := 16#328#; --
    constant mhpmevent9_addr : integer := 16#329#; --
    constant mhpmevent10_addr : integer := 16#32a#; --
    constant mhpmevent11_addr : integer := 16#32b#; --
    constant mhpmevent12_addr : integer := 16#32c#; --
    constant mhpmevent13_addr : integer := 16#32d#; --
    constant mhpmevent14_addr : integer := 16#32e#; --
    constant mhpmevent15_addr : integer := 16#32f#; --
    constant mhpmevent16_addr : integer := 16#330#; --
    constant mhpmevent17_addr : integer := 16#331#; --
    constant mhpmevent18_addr : integer := 16#332#; --
    constant mhpmevent19_addr : integer := 16#333#; --
    constant mhpmevent20_addr : integer := 16#334#; --
    constant mhpmevent21_addr : integer := 16#335#; --
    constant mhpmevent22_addr : integer := 16#336#; --
    constant mhpmevent23_addr : integer := 16#337#; --
    constant mhpmevent24_addr : integer := 16#338#; --
    constant mhpmevent25_addr : integer := 16#339#; --
    constant mhpmevent26_addr : integer := 16#33a#; --
    constant mhpmevent27_addr : integer := 16#33b#; --
    constant mhpmevent28_addr : integer := 16#33c#; --
    constant mhpmevent29_addr : integer := 16#33d#; --
    constant mhpmevent30_addr : integer := 16#33e#; --
    constant mhpmevent31_addr : integer := 16#33f#; --
    
    -- Debug registers
    constant dcsr_addr : integer := 16#7b0#; --
    constant dpc_addr : integer := 16#7b1#; --
    constant tselect_addr : integer := 16#7a0#; --
    constant tdata1_addr : integer := 16#7a1#; --
    constant tdata2_addr : integer := 16#7a2#; --
    constant tinfo_addr : integer := 16#7a4#; --

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
    
    
    -- Component description of the RISC-V SoC
    component riscv is
        generic (-- The frequency of the system
                  SYSTEM_FREQUENCY : integer;
                  -- Frequecy of the hardware clock
                  CLOCK_FREQUENCY : integer;
                  -- Have On-chip debugger?
                  HAVE_OCD : boolean;
                  -- Do we have a bootloader ROM?
                  HAVE_BOOTLOADER_ROM : boolean;
                  -- Disable CSR address check when in debug mode
                  OCD_CSR_CHECK_DISABLE : boolean;
                  -- RISCV E (embedded) of RISCV I (full)
                  HAVE_RISCV_E : boolean;
                  -- Do we have the integer multiply/divide unit?
                  HAVE_MULDIV : boolean;
                  -- Fast divide (needs more area)?
                  FAST_DIVIDE : boolean;
                  -- Do we have Zba (sh?add)
                  HAVE_ZBA : boolean;
                  -- Do we have Zbs (bit instructions)?
                  HAVE_ZBS : boolean;
                  -- Do we have Zicond (czero.{eqz|nez})?
                  HAVE_ZICOND : boolean;
                  -- Do we have HPM counters?
                  HAVE_ZIHPM : boolean;
                  -- Do we enable vectored mode for mtvec?
                  VECTORED_MTVEC : boolean;
                  -- Do we have registers is RAM?
                  HAVE_REGISTERS_IN_RAM : boolean;
                  -- Address width in bits, size is 2**bits
                  ROM_ADDRESS_BITS : integer;
                  -- Address width in bits, size is 2**bits
                  RAM_ADDRESS_BITS : integer;
                  -- 4 high bits of ROM address
                  ROM_HIGH_NIBBLE : memory_high_nibble;
                  -- 4 high bits of boot ROM address
                  BOOT_HIGH_NIBBLE : memory_high_nibble;
                  -- 4 high bits of RAM address
                  RAM_HIGH_NIBBLE : memory_high_nibble;
                  -- 4 high bits of I/O address
                  IO_HIGH_NIBBLE : memory_high_nibble;
                  -- Do we use fast store?
                  HAVE_FAST_STORE : boolean;
                  -- Do we have UART1?
                  HAVE_UART1 : boolean;
                  -- Do we have SPI1?
                  HAVE_SPI1 : boolean;
                  -- Do we have SPI2?
                  HAVE_SPI2 : boolean;
                  -- Do we have I2C1?
                  HAVE_I2C1 : boolean;
                  -- Do we have I2C2?
                  HAVE_I2C2 : boolean;
                  -- Do we have TIMER1?
                  HAVE_TIMER1 : boolean;
                  -- Do we have TIMER2?
                  HAVE_TIMER2 : boolean;
                  -- use watchdog?
                  HAVE_WDT : boolean;
                  -- UART1 BREAK triggers system reset
                  UART1_BREAK_RESETS : boolean
             );
        port (I_clk : in std_logic;
              I_areset : in std_logic;
              -- JTAG connection
              I_trst : in  std_logic;
              I_tck  : in  std_logic;
              I_tms  : in  std_logic;
              I_tdi  : in  std_logic;
              O_tdo  : out std_logic;
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

    -- Function to reduce an OR of std_logic_vector bits
    function or_reduce(input : std_logic_vector) return std_logic;

    -- Function to reduce an AND of std_logic_vector bits
    function and_reduce(input : std_logic_vector) return std_logic;
    
    -- Function to reduce an EXOR of std_logic_vector bits
    function xor_reduce(input : std_logic_vector) return std_logic;

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

    -- Function to reduce an OR of std_logic_vector bits
    function or_reduce(input : std_logic_vector) return std_logic is
    variable or_v : std_logic := '0';
    begin
        for i in input'range loop
            or_v := or_v or input(i);
        end loop;
        return or_v;
    end function or_reduce;

    -- Function to reduce an AND of std_logic_vector bits
    function and_reduce(input : std_logic_vector) return std_logic is
    variable and_v : std_logic := '1';
    begin
        for i in input'range loop
            and_v := and_v and input(i);
        end loop;
        return and_v;
    end function and_reduce;

    -- Function to reduce an EXOR of std_logic_vector bits
    function xor_reduce(input : std_logic_vector) return std_logic is
    variable xor_v : std_logic := '0';
    begin
        for i in input'range loop
            xor_v := xor_v and input(i);
        end loop;
        return xor_v;
    end function xor_reduce;
    
end package body processor_common;