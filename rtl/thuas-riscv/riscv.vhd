-- #################################################################################################
-- # riscv.vhd - The top level of the processor                                                    #
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

-- This file contains the description of a RISC-V RV32IM top level,
-- including the core (using a three-stage pipeline), and address
-- decoding unit, RAM, ROM, boot ROM and I/O.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.processor_common.all;

-- The microcontroller
entity riscv is
    generic (
         -- The frequency of the system
          SYSTEM_FREQUENCY : integer;
          -- Frequecy of the hardware clock
          CLOCK_FREQUENCY : integer;
          -- Have On-chip debugger?
          HAVE_OCD : boolean;
          -- Do we have a bootloader ROM?
          HAVE_BOOTLOADER_ROM : boolean;
          -- Disable CSR address check when in debug mode
          OCD_CSR_CHECK_DISABLE : boolean;
          -- Do we use post-increment address pointer when debugging?
          OCD_AAMPOSTINCREMENT : boolean;
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
          -- Use Machine-mode Software Interrupt?
          HAVE_MSI : boolean;
          -- Use watchdog?
          HAVE_WDT : boolean;
          -- UART1 BREAK triggers system reset
          UART1_BREAK_RESETS : boolean
         );
    port (I_clk : in std_logic;
          I_areset : in std_logic;
          -- JTAG connection
          I_trst : in  std_logic;
          I_tms  : in  std_logic;
          I_tck  : in  std_logic;
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
end entity riscv;

architecture rtl of riscv is
component core is
    generic (
          -- The frequency of the system
          SYSTEM_FREQUENCY : integer;
          -- Hardware version in BCD
          HW_VERSION : integer;
          -- RISCV E (embedded) or RISCV I (full)
          HAVE_RISCV_E : boolean;
          -- Have On-chip debugger?
          HAVE_OCD : boolean;
          -- Disable CSR address check when in debug mode
          OCD_CSR_CHECK_DISABLE : boolean;
          -- Do we have the integer multiply/divide unit?
          HAVE_MULDIV : boolean;
          -- Fast divide (needs more area)?
          FAST_DIVIDE : boolean;
          -- Do we have Zba (sh?add)
          HAVE_ZBA : boolean;
          -- Do we have Zbs (bit instructions)?
          HAVE_ZBS : boolean;
          -- Do we have Zicnd (czero.{eqz|nez})?
          HAVE_ZICOND : boolean;
          -- Do we have HPM counters?
          HAVE_ZIHPM : boolean;
          -- Do we enable vectored mode for mtvec?
          VECTORED_MTVEC : boolean;
          -- Do we have registers is RAM?
          HAVE_REGISTERS_IN_RAM : boolean;
          -- If bootloader enabled, adjust the boot address
          HAVE_BOOTLOADER_ROM : boolean;
          -- 4 high bits of ROM address
          ROM_HIGH_NIBBLE : memory_high_nibble;
          -- 4 high bits of boot ROM address
          BOOT_HIGH_NIBBLE : memory_high_nibble;
          -- Do we have fast store?
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
          -- Use Machine-mode Software Interrupt?
          HAVE_MSI : boolean;
          -- Use watchdog?
          HAVE_WDT : boolean;
          -- UART1 BREAK triggers system reset
          UART1_BREAK_RESETS : boolean
         );
    port (I_clk : in std_logic;
          I_areset : in std_logic;
          -- Instruction request from ROM
          O_instr_request : out instr_request_type;
          I_instr_response : in instr_response_type;
          -- To memory
          O_bus_request : out bus_request_type;
          -- from memory
          I_bus_response : in bus_response_type;
          -- Interrupt signals from I/O
          I_intrio : data_type;
          -- time from the memory mapped I/O
          I_mtime : in data_type;
          I_mtimeh : in data_type;
          -- Debug signals
          I_dm_core_data_request : in dm_core_data_request_type;
          O_dm_core_data_response : out dm_core_data_response_type;
          I_halt_req : in std_logic;
          I_resume_req : in std_logic;
          I_ackhavereset : in std_logic;
          O_halt_ack : out std_logic;
          O_reset_ack : out std_logic;
          O_resume_ack : out std_logic
         );
end component core;
component address_decode is
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
end component address_decode;
component instr_router is
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
end component instr_router;
component rom is
    generic (
          HAVE_BOOTLOADER_ROM : boolean;
          HAVE_OCD : boolean;
          ROM_ADDRESS_BITS : integer;
          HAVE_FAST_STORE : boolean
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
end component rom;
component ram is
    generic (
          RAM_ADDRESS_BITS : integer;
          HAVE_FAST_STORE : boolean
         );
    port (I_clk : in std_logic;
          I_areset : in std_logic;
          -- From address decoder
          I_mem_request : in mem_request_type;
          -- To address decoder
          O_mem_response : out mem_response_type
         );
end component ram;
component bootloader is
    generic (
          HAVE_BOOTLOADER_ROM : boolean
         );
    port (I_clk : in std_logic;
          I_areset : in std_logic;
          -- From core
          I_instr_request : in instr_request_type;
          O_instr_response : out instr_response2_type;
          -- From address decoder
          I_mem_request : in mem_request_type;
          -- To address decoder
          O_mem_response : out mem_response_type
         );
end component bootloader;
component io is
    generic (
          -- The frequency of the system
          SYSTEM_FREQUENCY : integer;
          -- Frequency of the clock (1 MHz)_
          CLOCK_FREQUENCY : integer;
          -- Do we have fast store?
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
          HAVE_TIMER1 : boolean ;
          -- Do we have TIMER2?
          HAVE_TIMER2 : boolean;
          -- Use Machine-mode Software Interrupt?
          HAVE_MSI : boolean;
          -- Use watchdog?
          HAVE_WDT : boolean;
          -- UART1 BREAK triggers system reset
          UART1_BREAK_RESETS : boolean
         );             
    port (I_clk : in std_logic;
          I_areset : in std_logic;
          -- From address decoder
          I_mem_request : in mem_request_type;
          -- To address decoder
          O_mem_response : out mem_response_type;
          -- Connection with outside world
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
          -- SPI2
          O_spi2sck : out std_logic;
          O_spi2mosi : out std_logic;
          I_spi2miso : in std_logic;
          -- TIMER2
          O_timer2oct : out std_logic;
          IO_timer2icoca : inout std_logic;
          IO_timer2icocb : inout std_logic;
          IO_timer2icocc : inout std_logic;
          -- TIME and TIMEH
          O_mtime : out data_type;
          O_mtimeh : out data_type;
          -- Hardware interrupt request
          O_intrio : out data_type;
          -- Break on UART1 received
          O_break_received : out std_logic;
          -- Reset from WDT
          O_reset_from_wdt : out std_logic
         );
end component io;
-- Reused from NEORV32 bu S.T. Nolting <www.neorv32.org>
component dtm is
    generic (
          IDCODE_VERSION : std_logic_vector(03 downto 0); -- version
          IDCODE_PARTID  : std_logic_vector(15 downto 0); -- part number
          IDCODE_MANID   : std_logic_vector(10 downto 0)  -- manufacturer id
         );
    port (I_clk       : in  std_logic;
          I_areset    : in  std_logic;
          -- JTAG connection
          I_trst : in  std_logic;
          I_tck  : in  std_logic;
          I_tms  : in  std_logic;
          I_tdi  : in  std_logic;
          O_tdo  : out std_logic;
          -- Debug module interface (DMI)
          O_dmi_request   : out dmi_request_type;
          I_dmi_response  : in  dmi_response_type
         );
end component dtm;
component dm is
    generic (
          OCD_AAMPOSTINCREMENT : boolean
         );
    port (I_clk : std_logic;
          I_areset : std_logic;
          -- Debug module interface (DMI)
          I_dmi_request : in dmi_request_type;
          O_dmi_response : out dmi_response_type;
          -- Debug signals
          O_reset_req : out std_logic;
          I_reset_ack : in std_logic;
          O_halt_req : out std_logic;
          I_halt_ack : in std_logic;
          O_resume_req : out std_logic;
          I_resume_ack : in std_logic;     
          O_ackhavereset : out std_logic;     
          O_dm_core_data_request : out dm_core_data_request_type;
          I_dm_core_data_response : in dm_core_data_response_type
         );
end component dm;


-- The clock
signal clk_int : std_logic;

-- Instruction fetch from ROM and boot ROM
signal instr_request_int : instr_request_type;
signal instr_response_int : instr_response_type;
signal instr_request_rom_int : instr_request_type;
signal instr_response_rom_int : instr_response2_type;
signal instr_request_boot_int : instr_request_type;
signal instr_response_boot_int : instr_response2_type;

-- Memory access signals from core to address decoder
signal bus_request_int : bus_request_type;
signal bus_response_int : bus_response_type;
-- Memory access signals from address decoder to memories
signal mem_request_rom_int : mem_request_type;
signal mem_request_boot_int : mem_request_type;
signal mem_request_ram_int : mem_request_type;
signal mem_request_io_int : mem_request_type;
signal mem_response_rom_int : mem_response_type;
signal mem_response_boot_int : mem_response_type;
signal mem_response_ram_int : mem_response_type;
signal mem_response_io_int : mem_response_type;

-- MTIME from I/O (memory mapped)
signal mtime_int : data_type;
signal mtimeh_int : data_type;

-- Interrupts from I/O to core
signal intrio_int : data_type;

-- Signals for reset
signal areset_sys_sync_int : std_logic_vector(3 downto 0);
signal areset_sys_int : std_logic;
signal break_from_uart1_int : std_logic;
signal reset_from_wdt_int : std_logic;
signal areset_debug_sync_int : std_logic_vector(1 downto 0);
signal areset_debug_int : std_logic;

-- Signals between DTM and DM
signal dmi_request_int : dmi_request_type;
signal dmi_response_int : dmi_response_type;
--
signal halt_req_int, halt_ack_int : std_logic;
signal resume_req_int, resume_ack_int : std_logic;
signal reset_req_int, reset_ack_int : std_logic;
signal ackhavereset_int : std_logic;
--
signal dm_core_data_request_int : dm_core_data_request_type;
signal dm_core_data_response_int : dm_core_data_response_type;



begin

    -- Just pass on the clock
    clk_int <= I_clk;

    
    -- Synchronize the asynchronous reset.
    -- Also: reset the system if an UART1 BREAK is detected
    -- or watchdog reset or debug reset.
    process (I_clk, I_areset) is
    begin
        if I_areset = '1' then
            areset_sys_sync_int   <= (others => '0');
            areset_sys_int        <= '1';
            areset_debug_sync_int <= (others => '0');
            areset_debug_int      <= '1';
        elsif rising_edge(I_clk) then
            -- Reset for the debug units
            areset_debug_sync_int <= areset_debug_sync_int(areset_debug_sync_int'left-1 downto 0) & '1';
            areset_debug_int <= not and_reduce(areset_debug_sync_int);
            -- If a UART1 BREAK is detected or watchdog reset or debug reset, reset the system
            if break_from_uart1_int = '1' or reset_from_wdt_int = '1' or reset_req_int = '1' then
                areset_sys_sync_int <= (others => '0');
            else
                areset_sys_sync_int <= areset_sys_sync_int(areset_sys_sync_int'left-1 downto 0) & '1';
            end if;
            areset_sys_int <= not and_reduce(areset_sys_sync_int);
        end if;
    end process;
    
    core0: core
    generic map (
              SYSTEM_FREQUENCY => SYSTEM_FREQUENCY,
              HW_VERSION => HW_VERSION,
              HAVE_RISCV_E => HAVE_RISCV_E,
              HAVE_OCD => HAVE_OCD,
              OCD_CSR_CHECK_DISABLE => OCD_CSR_CHECK_DISABLE,
              HAVE_MULDIV => HAVE_MULDIV,
              FAST_DIVIDE => FAST_DIVIDE,
              HAVE_ZBA => HAVE_ZBA,
              HAVE_ZBS => HAVE_ZBS,
              HAVE_ZICOND => HAVE_ZICOND,
              HAVE_ZIHPM => HAVE_ZIHPM,
              VECTORED_MTVEC => VECTORED_MTVEC,
              HAVE_REGISTERS_IN_RAM => HAVE_REGISTERS_IN_RAM,
              HAVE_BOOTLOADER_ROM => HAVE_BOOTLOADER_ROM,
              ROM_HIGH_NIBBLE => ROM_HIGH_NIBBLE,
              BOOT_HIGH_NIBBLE => BOOT_HIGH_NIBBLE,
              HAVE_FAST_STORE => HAVE_FAST_STORE,
              HAVE_UART1 => HAVE_UART1,
              HAVE_SPI1 => HAVE_SPI1,
              HAVE_SPI2 => HAVE_SPI2,
              HAVE_I2C1 => HAVE_I2C1,
              HAVE_I2C2 => HAVE_I2C2,
              HAVE_TIMER1 => HAVE_TIMER1,
              HAVE_TIMER2 => HAVE_TIMER2,
              HAVE_MSI => HAVE_MSI,
              HAVE_WDT => HAVE_WDT,
              UART1_BREAK_RESETS => UART1_BREAK_RESETS
             )
    port map (I_clk => clk_int,
              I_areset => areset_sys_int,
              -- Instruction fetch
              O_instr_request => instr_request_int,
              I_instr_response => instr_response_int,
              -- Data fetch/store
              O_bus_request => bus_request_int,
              I_bus_response => bus_response_int,
              -- Pending insterrupts
              I_intrio => intrio_int,
              -- [m]time
              I_mtime => mtime_int,
              I_mtimeh => mtimeh_int,
              -- Debug signals
              I_dm_core_data_request => dm_core_data_request_int,
              O_dm_core_data_response => dm_core_data_response_int,
              I_halt_req => halt_req_int,
              I_resume_req => resume_req_int,
              I_ackhavereset => ackhavereset_int,
              O_halt_ack => halt_ack_int,
              O_reset_ack => reset_ack_int,
              O_resume_ack => resume_ack_int
             );
    
    address_decode0: address_decode
    generic map (
              ROM_HIGH_NIBBLE => ROM_HIGH_NIBBLE,
              BOOT_HIGH_NIBBLE => BOOT_HIGH_NIBBLE,
              RAM_HIGH_NIBBLE => RAM_HIGH_NIBBLE,
              IO_HIGH_NIBBLE => IO_HIGH_NIBBLE
             )
    port map (I_clk => clk_int,
              I_areset => areset_sys_int,
              --
              I_bus_request => bus_request_int,
              O_bus_response => bus_response_int,
              --
              O_mem_request_rom => mem_request_rom_int,
              O_mem_request_boot => mem_request_boot_int,
              O_mem_request_ram => mem_request_ram_int,
              O_mem_request_io => mem_request_io_int,
              --
              I_mem_response_rom => mem_response_rom_int,
              I_mem_response_boot => mem_response_boot_int,
              I_mem_response_ram => mem_response_ram_int,
              I_mem_response_io => mem_response_io_int
    );
    
    instr_route0: instr_router
    generic map (
              HAVE_BOOTLOADER_ROM => HAVE_BOOTLOADER_ROM,
              ROM_HIGH_NIBBLE => ROM_HIGH_NIBBLE,
              BOOT_HIGH_NIBBLE => BOOT_HIGH_NIBBLE
             )
    port map (I_instr_request => instr_request_int,
              O_instr_response => instr_response_int,
              --
              O_instr_request_rom => instr_request_rom_int,
              I_instr_response_rom => instr_response_rom_int,
              --
              O_instr_request_boot => instr_request_boot_int,
              I_instr_response_boot => instr_response_boot_int
             );
    
    rom0: rom
    generic map (
              HAVE_BOOTLOADER_ROM => HAVE_BOOTLOADER_ROM,
              HAVE_OCD => HAVE_OCD,
              ROM_ADDRESS_BITS => ROM_ADDRESS_BITS,
              HAVE_FAST_STORE => HAVE_FAST_STORE
             )
    port map (I_clk => clk_int,
              I_areset => areset_sys_int,
              -- fetch instruction
              I_instr_request => instr_request_rom_int,
              O_instr_response => instr_response_rom_int,
              I_mem_request => mem_request_rom_int,
              O_mem_response => mem_response_rom_int
             );

    bootloader0: bootloader
    generic map (
              HAVE_BOOTLOADER_ROM => HAVE_BOOTLOADER_ROM
             )
    port map (I_clk => clk_int,
              I_areset => areset_sys_int,
              --
              I_instr_request => instr_request_boot_int,
              O_instr_response => instr_response_boot_int,
              --
              I_mem_request => mem_request_boot_int,
              O_mem_response => mem_response_boot_int
             );
        
    ram0: ram
    generic map (
              RAM_ADDRESS_BITS => RAM_ADDRESS_BITS,
              HAVE_FAST_STORE => HAVE_FAST_STORE
             )
    port map (I_clk => clk_int,
              I_areset => areset_sys_int,
              --
              I_mem_request => mem_request_ram_int,
              O_mem_response => mem_response_ram_int
             );

    io0: io
    generic map (
              SYSTEM_FREQUENCY => SYSTEM_FREQUENCY,
              CLOCK_FREQUENCY => CLOCK_FREQUENCY,
              HAVE_FAST_STORE => HAVE_FAST_STORE,
              HAVE_UART1 => HAVE_UART1,
              HAVE_SPI1 => HAVE_SPI1,
              HAVE_SPI2 => HAVE_SPI2,
              HAVE_I2C1 => HAVE_I2C1,
              HAVE_I2C2 => HAVE_I2C2,
              HAVE_TIMER1 => HAVE_TIMER1,
              HAVE_TIMER2 => HAVE_TIMER2,
              HAVE_MSI => HAVE_MSI,
              HAVE_WDT => HAVE_WDT,
              UART1_BREAK_RESETS => UART1_BREAK_RESETS
             )
    port map (I_clk => clk_int,
              I_areset => areset_sys_int,
              --
              I_mem_request => mem_request_io_int,
              O_mem_response => mem_response_io_int,
              -- GPIOA
              I_gpioapin => I_gpioapin,
              O_gpioapout => O_gpioapout,
              -- UART1
              I_uart1rxd => I_uart1rxd,
              O_uart1txd => O_uart1txd,
              -- I2C1
              IO_i2c1scl => IO_i2c1scl,
              IO_i2c1sda => IO_i2c1sda,
              -- I2C2
              IO_i2c2scl => IO_i2c2scl,
              IO_i2c2sda => IO_i2c2sda,
              -- SPI1
              O_spi1sck => O_spi1sck,
              O_spi1mosi => O_spi1mosi,
              I_spi1miso => I_spi1miso,
              -- SPI2
              O_spi2sck => O_spi2sck,
              O_spi2mosi => O_spi2mosi,
              I_spi2miso => I_spi2miso,
              -- TIMER2
              O_timer2oct => O_timer2oct,
              IO_timer2icoca => IO_timer2icoca,
              IO_timer2icocb => IO_timer2icocb,
              IO_timer2icocc => IO_timer2icocc,
              -- TIME/TIMEH
              O_mtime => mtime_int,
              O_mtimeh => mtimeh_int,
              -- Interrupt requests
              O_intrio => intrio_int,
              -- BREAK received on UART1
              O_break_received => break_from_uart1_int,
              -- Reset from WDT
              O_reset_from_wdt => reset_from_wdt_int
             );

    debuggen : if HAVE_OCD generate
        -- Reused from NEORV32 by S.T. Nolting <www.neorv32.org>
        dtm0: dtm
        generic map (
                  IDCODE_VERSION => "0000",
                  IDCODE_PARTID  => x"face",
                  IDCODE_MANID   => "00000000000"
                 )
        port map (I_clk => I_clk,
                  I_areset => areset_debug_int,
                  I_trst => I_trst,
                  I_tck => I_tck,
                  I_tms => I_tms,
                  I_tdi => I_tdi,
                  O_tdo => O_tdo,
                  --
                  O_dmi_request => dmi_request_int,
                  I_dmi_response => dmi_response_int
                 );
        
        -- Debug Module
        dm0: dm
        generic map (
                  OCD_AAMPOSTINCREMENT => OCD_AAMPOSTINCREMENT
                 )
        port map (I_clk => I_clk,
                  I_areset => areset_debug_int,
                  --
                  I_dmi_request => dmi_request_int,
                  O_dmi_response => dmi_response_int,
                  --
                  O_reset_req => reset_req_int,
                  I_reset_ack => reset_ack_int,
                  O_halt_req => halt_req_int,
                  I_halt_ack => halt_ack_int,
                  O_resume_req => resume_req_int,
                  I_resume_ack => resume_ack_int,
                  O_ackhavereset => ackhavereset_int,
                  --
                  O_dm_core_data_request => dm_core_data_request_int,
                  I_dm_core_data_response => dm_core_data_response_int
                 );
    end generate debuggen;
    
    notdebuggen : if not HAVE_OCD generate
        -- Connect TDO to TDI, so that the scan chain stays intact
        O_tdo <= I_tdi;
        reset_req_int <= '0';
        halt_req_int <='0';
        resume_req_int <= '0';
        ackhavereset_int <= '0';
        
        dm_core_data_request_int.address <= (others => '0');
        dm_core_data_request_int.data <= (others => '0');
        dm_core_data_request_int.size <= (others => '0');
        dm_core_data_request_int.readcsr <= '0';
        dm_core_data_request_int.readgpr <= '0';
        dm_core_data_request_int.readmem <= '0';
        dm_core_data_request_int.writecsr <= '0';
        dm_core_data_request_int.writegpr <= '0';
        dm_core_data_request_int.writemem <= '0';
    end generate notdebuggen;
    
end architecture rtl;
