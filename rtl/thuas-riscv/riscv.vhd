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
          -- Do we have a bootloader ROM?
          HAVE_BOOTLOADER_ROM : boolean;
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
end entity riscv;

architecture rtl of riscv is
component core is
    generic (
          -- The frequency of the system
          SYSTEM_FREQUENCY : integer;
          -- Hardware version in BCD
          HW_VERSION : integer;
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
          I_mtimeh : in data_type
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
component instruction_router is
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
end component instruction_router;
component rom is
    generic (
          HAVE_BOOTLOADER_ROM : boolean;
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
          -- use watchdog?
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
          O_spi1nss : out std_logic;
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

-- The clock and the external reset
signal clk_int : std_logic;
signal areset_int : std_logic;

signal instr_request_int : instr_request_type;
signal instr_response_int : instr_response_type;

signal instr_request_rom_int : instr_request_type;
signal instr_response_rom_int : instr_response2_type;

signal instr_request_boot_int : instr_request_type;
signal instr_response_boot_int : instr_response2_type;

-- Data in and out of the core
signal dataout_int : data_type;
signal datain_int : data_type;

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

-- interrupts from I/O to core
signal intrio_int : data_type;

-- Instruction access error (now:unimplemented memory)
signal instr_access_error_int : std_logic;

-- Signals for reset
signal areset_sys_sync_int : std_logic_vector(3 downto 0);
signal areset_sys_int : std_logic;
signal break_from_uart1_int : std_logic;
signal reset_from_wdt_int : std_logic;

begin

    -- Just pass on the clock
    clk_int <= I_clk;
    -- Reset from reset synchronizer
    areset_int <= areset_sys_int;
    
    -- Synchronize the asynchronous reset.
    -- Also: reset the system if a UART1 BREAK is detected
    -- or when the watchdog timer expires.
    process (I_clk, I_areset) is
    begin
        if I_areset = '1' then
            areset_sys_sync_int <= (others => '0');
            areset_sys_int      <= '1';
        elsif rising_edge(I_clk) then
            -- If a UART1 BREAK is detected, reset the system
            if break_from_uart1_int = '1' or reset_from_wdt_int = '1' then
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
              HAVE_WDT => HAVE_WDT,
              UART1_BREAK_RESETS => UART1_BREAK_RESETS
             )
    port map (I_clk => clk_int,
              I_areset => areset_int,
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
              I_mtimeh => mtimeh_int
             );
    
    address_decode0: address_decode
    generic map (
              ROM_HIGH_NIBBLE => ROM_HIGH_NIBBLE,
              BOOT_HIGH_NIBBLE => BOOT_HIGH_NIBBLE,
              RAM_HIGH_NIBBLE => RAM_HIGH_NIBBLE,
              IO_HIGH_NIBBLE => IO_HIGH_NIBBLE
             )
    port map (I_clk => clk_int,
              I_areset => areset_int,
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
    
    instr_route0: instruction_router
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
              ROM_ADDRESS_BITS => ROM_ADDRESS_BITS,
              HAVE_FAST_STORE => HAVE_FAST_STORE
             )
    port map (I_clk => clk_int,
              I_areset => areset_int,
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
              I_areset => areset_int,
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
              I_areset => areset_int,
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
              HAVE_WDT => HAVE_WDT,
              UART1_BREAK_RESETS => UART1_BREAK_RESETS
             )
    port map (I_clk => clk_int,
              I_areset => areset_int,
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
              O_spi1nss => O_spi1nss,
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

end architecture rtl;
