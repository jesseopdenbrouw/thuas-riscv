-- #################################################################################################
-- # riscv.vhd - The top level of the processor                                                    #
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
-- #################################################################################################

-- This file contains the description of a RISC-V RV32IM microcontroller
-- including the core (using a three-stage pipeline), and address
-- decoding unit, RAM, ROM, boot ROM, I/O and debug modules.

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
          -- Do we have Zbb (bit instructions)?
          HAVE_ZBB : boolean;
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
          -- Buffer I/O response
          BUFFER_IO_RESPONSE : boolean;
          -- Do we have UART1?
          HAVE_UART1 : boolean;
          -- Do we have UART1?
          HAVE_UART2 : boolean;
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
          -- Use CRC?
          HAVE_CRC : boolean;
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
          -- UART2
          I_uart2rxd : in std_logic;
          O_uart2txd : out std_logic;
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
          -- Do we have Zbb (bit instructions)?
          HAVE_ZBB : boolean;
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
          -- Buffer I/O response
          BUFFER_IO_RESPONSE : boolean;
          -- Do we have UART1?
          HAVE_UART1 : boolean;
          -- Do we have UART2?
          HAVE_UART2 : boolean;
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
          -- Use CRC?
          HAVE_CRC : boolean;
          -- UART1 BREAK triggers system reset
          UART1_BREAK_RESETS : boolean
         );
    port (I_clk : in std_logic;
          I_areset : in std_logic;
          I_sreset : in std_logic;
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
          -- Do we have boot ROM?
          HAVE_BOOTLOADER_ROM : boolean;
          -- 4 high bits of ROM address
          ROM_HIGH_NIBBLE : memory_high_nibble;
          -- 4 high bits of boot ROM address
          BOOT_HIGH_NIBBLE : memory_high_nibble;
          -- 4 high bits of RAM address
          RAM_HIGH_NIBBLE : memory_high_nibble;
          -- 4 high bits of I/O address
          IO_HIGH_NIBBLE : memory_high_nibble
         );
    port ( 
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
          ROM_ADDRESS_BITS : integer
         );
    port (
          I_clk : in std_logic;
          I_areset : in std_logic;
          I_sreset : in std_logic;
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
          RAM_ADDRESS_BITS : integer
         );
    port (
          I_clk : in std_logic;
          I_areset : in std_logic;
          I_sreset : in std_logic;
          -- From address decoder
          I_mem_request : in mem_request_type;
          -- To address decoder
          O_mem_response : out mem_response_type
         );
end component ram;
component bootrom is
    generic (
          HAVE_BOOTLOADER_ROM : boolean
         );
    port (
          I_clk : in std_logic;
          I_areset : in std_logic;
          I_sreset : in std_logic;
          -- From core
          I_instr_request : in instr_request_type;
          O_instr_response : out instr_response2_type;
          -- From address decoder
          I_mem_request : in mem_request_type;
          -- To address decoder
          O_mem_response : out mem_response_type
         );
end component bootrom;
-- Reused from NEORV32 bu S.T. Nolting <www.neorv32.org>
-- Debug Transport Module
component dtm is
    generic (
          IDCODE_VERSION : std_logic_vector(03 downto 0); -- version
          IDCODE_PARTID  : std_logic_vector(15 downto 0); -- part number
          IDCODE_MANID   : std_logic_vector(10 downto 0)  -- manufacturer id
         );
    port (
          I_clk       : in  std_logic;
          I_areset    : in  std_logic;
          I_sreset : in std_logic;
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
    port (
          I_clk : std_logic;
          I_areset : std_logic;
          I_sreset : in std_logic;
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
--
-- From here on: components for the I/O
--
-- I/O switch between Address_decode and I/O devices
-- Currently 16 devices max
component io_bus_switch is
    generic (
          -- Buffer the response (adds one clock latency)
          BUFFER_IO_RESPONSE : boolean
         );
    port (
          I_clk : in std_logic;
          I_areset : in std_logic;
          I_sreset : in std_logic;
          --
          I_mem_request : in mem_request_type;
          O_mem_response : out mem_response_type;
          --
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
end component io_bus_switch;

-- General Purpose I/O with one external interrupt
component gpio is
    port (
          I_clk : in std_logic;
          I_areset : in std_logic;
          I_sreset : in std_logic;
          -- 
          I_mem_request : in mem_request_type;
          O_mem_response : out mem_response_type;
          --
          I_pin : in data_type;
          O_pout: out data_type;
          O_irq : out std_logic
         );
end component gpio;

-- RISC-V External System Timer
component mtime is
    generic (
          SYSTEM_FREQUENCY : integer;
          CLOCK_FREQUENCY : integer
         );
    port (
          I_clk : in std_logic;
          I_areset : in std_logic;
          I_sreset : in std_logic;
          -- 
          I_mem_request : in mem_request_type;
          O_mem_response : out mem_response_type;
          --
          O_mtime : out data_type;
          O_mtimeh : out data_type;
          O_irq : out std_logic
         );
end component mtime;

-- Watchdog timer
component wdt is
    port (
          I_clk : in std_logic;
          I_areset : in std_logic;
          I_sreset : in std_logic;
          -- 
          I_mem_request : in mem_request_type;
          O_mem_response : out mem_response_type;
          --
          O_reset : out std_logic;
          O_irq : out std_logic
         );
end component wdt;

-- Machine mode Software Interrupt
component msi is
    port (
          I_clk : in std_logic;
          I_areset : in std_logic;
          I_sreset : in std_logic;
          -- 
          I_mem_request : in mem_request_type;
          O_mem_response : out mem_response_type;
          --
          O_irq : out std_logic
         );
end component msi;

-- Simple timer
component timera is
    port (
          I_clk : in std_logic;
          I_areset : in std_logic;
          I_sreset : in std_logic;
          -- 
          I_mem_request : in mem_request_type;
          O_mem_response : out mem_response_type;
          --
          O_irq : out std_logic
         );
end component timera;

-- Universal Asynchronous Receiver/Transmitter
component uart is
    generic (
          UART_BREAK_RESETS : boolean
         );
    port (
          I_clk : in std_logic;
          I_areset : in std_logic;
          I_sreset : in std_logic;
          -- 
          I_mem_request : in mem_request_type;
          O_mem_response : out mem_response_type;
          --
          I_rxd : in std_logic;
          O_txd: out std_logic;
          O_break_received : out std_logic;
          O_irq : out std_logic
         );
end component uart;    

-- I2C
component i2c is
    generic (
          SYSTEM_FREQUENCY : integer
         );
    port (
          I_clk : in std_logic;
          I_areset : in std_logic;
          I_sreset : in std_logic;
          -- 
          I_mem_request : in mem_request_type;
          O_mem_response : out mem_response_type;
          --
          IO_scl : inout std_logic;
          IO_sda : inout std_logic;
          O_irq : out std_logic
         );
end component i2c;

-- SPI
component spi is
    port (
          I_clk : in std_logic;
          I_areset : in std_logic;
          I_sreset : in std_logic;
          -- 
          I_mem_request : in mem_request_type;
          O_mem_response : out mem_response_type;
          --
          O_sck : out std_logic;
          O_mosi : out std_logic;
          I_miso : in std_logic;
          O_irq : out std_logic
         );
end component spi;

-- A more elaborate timer
component timerb is
    port (
          I_clk : in std_logic;
          I_areset : in std_logic;
          I_sreset : in std_logic;
          -- 
          I_mem_request : in mem_request_type;
          O_mem_response : out mem_response_type;
          --
          O_timeroct : out std_logic;
          IO_timericoca : inout std_logic;
          IO_timericocb : inout std_logic;
          IO_timericocc : inout std_logic;
          
          O_irq : out std_logic
         );
end component timerb;

-- CRC unit
component crc is
    port (
          I_clk : in std_logic;
          I_areset : in std_logic;
          I_sreset : in std_logic;
          -- 
          I_mem_request : in mem_request_type;
          O_mem_response : out mem_response_type
         );
end component crc;

--Generic stub for I/O
component stub is
    port (
          I_clk : in std_logic;
          I_areset : in std_logic;
          I_sreset : in std_logic;
          -- 
          I_mem_request : in mem_request_type;
          O_mem_response : out mem_response_type
         );
end component stub;

-- The clock and the external reset
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
signal sreset_sys_int : std_logic;
signal sreset_debug_int : std_logic;

-- Signals between DTM and DM
signal dmi_request_int : dmi_request_type;
signal dmi_response_int : dmi_response_type;
-- Run/Halt signals from DM to core
signal halt_req_int, halt_ack_int : std_logic;
signal resume_req_int, resume_ack_int : std_logic;
signal reset_req_int, reset_ack_int : std_logic;
signal ackhavereset_int : std_logic;
-- DM to core data signals
signal dm_core_data_request_int : dm_core_data_request_type;
signal dm_core_data_response_int : dm_core_data_response_type;

-- Buses between I/O bus switch and I/O modules
signal gpioa_request_int : mem_request_type;
signal gpioa_response_int : mem_response_type;
signal uart1_request_int : mem_request_type;
signal uart1_response_int : mem_response_type;
signal i2c1_request_int : mem_request_type;
signal i2c1_response_int : mem_response_type;
signal i2c2_request_int : mem_request_type;
signal i2c2_response_int : mem_response_type;
signal spi1_request_int : mem_request_type;
signal spi1_response_int : mem_response_type;
signal spi2_request_int : mem_request_type;
signal spi2_response_int : mem_response_type;
signal timer1_request_int : mem_request_type;
signal timer1_response_int : mem_response_type;
signal timer2_request_int : mem_request_type;
signal timer2_response_int : mem_response_type;
signal wdt_request_int : mem_request_type;
signal wdt_response_int : mem_response_type;
signal msi_request_int : mem_request_type;
signal msi_response_int : mem_response_type;
signal mtime_request_int : mem_request_type;
signal mtime_response_int : mem_response_type;
signal uart2_request_int : mem_request_type;
signal uart2_response_int : mem_response_type;
signal crc_request_int : mem_request_type;
signal crc_response_int : mem_response_type;
signal stub13_request_int : mem_request_type;
signal stub13_response_int : mem_response_type;
signal stub14_request_int : mem_request_type;
signal stub14_response_int : mem_response_type;
signal stub15_request_int : mem_request_type;
signal stub15_response_int : mem_response_type;

-- IRQ signals
signal irq_gpioa_int : std_logic;
signal irq_uart1_int : std_logic;
signal irq_mtime_int : std_logic;
signal irq_wdt_int : std_logic;
signal irq_msi_int : std_logic;
signal irq_i2c1_int : std_logic;
signal irq_i2c2_int : std_logic;
signal irq_spi1_int : std_logic;
signal irq_spi2_int : std_logic;
signal irq_timer1_int : std_logic;
signal irq_timer2_int : std_logic;
signal irq_uart2_int : std_logic;

-- Have synchronous reset?
type reset_type is (full_async, full_sync, mixed);
constant RESET_METHOD : reset_type := full_async;

begin

    -- Just pass on the clock
    clk_int <= I_clk;

    
    -- Use full asynchronous reset.
    -- Implements global reset (all modules)
    -- Implements system reset (all modules except DM and DTM)
    async_reset_gen: if RESET_METHOD = full_async generate
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
        sreset_debug_int <= '0';
        sreset_sys_int <= '0';
    end generate;

    -- Use full synchronous reset
    -- sreset_debug_int implements reset for debug modules
    -- sreset_sys_int implements reset for other modules
    syn_reset_gen: if RESET_METHOD = full_sync generate
        -- Synchronize the asynchronous reset
        process (clk_int, I_areset) is
        begin
            if rising_edge(clk_int) then
                areset_sys_sync_int <= areset_sys_sync_int(areset_sys_sync_int'left-1 downto 0) & I_areset;
            end if;
        end process;
        -- Synchronous reset for debug modules
        sreset_debug_int <= areset_sys_sync_int(areset_sys_sync_int'left);
        -- Synchronous reset from external reset or UART1 break detect or watchdog or debug modules
        sreset_sys_int <= sreset_debug_int or break_from_uart1_int or reset_from_wdt_int or reset_req_int;
        -- Disable asynchronous reset

        areset_sys_int <= '0';
        areset_debug_int <= '0';
    end generate;
    
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
              HAVE_ZBB => HAVE_ZBB,
              HAVE_ZBS => HAVE_ZBS,
              HAVE_ZICOND => HAVE_ZICOND,
              HAVE_ZIHPM => HAVE_ZIHPM,
              VECTORED_MTVEC => VECTORED_MTVEC,
              HAVE_REGISTERS_IN_RAM => HAVE_REGISTERS_IN_RAM,
              HAVE_BOOTLOADER_ROM => HAVE_BOOTLOADER_ROM,
              ROM_HIGH_NIBBLE => ROM_HIGH_NIBBLE,
              BOOT_HIGH_NIBBLE => BOOT_HIGH_NIBBLE,
              BUFFER_IO_RESPONSE => BUFFER_IO_RESPONSE,
              HAVE_UART1 => HAVE_UART1,
              HAVE_UART2 => HAVE_UART2,
              HAVE_SPI1 => HAVE_SPI1,
              HAVE_SPI2 => HAVE_SPI2,
              HAVE_I2C1 => HAVE_I2C1,
              HAVE_I2C2 => HAVE_I2C2,
              HAVE_TIMER1 => HAVE_TIMER1,
              HAVE_TIMER2 => HAVE_TIMER2,
              HAVE_MSI => HAVE_MSI,
              HAVE_WDT => HAVE_WDT,
              HAVE_CRC => HAVE_CRC,
              UART1_BREAK_RESETS => UART1_BREAK_RESETS
             )
    port map (I_clk => clk_int,
              I_areset => areset_sys_int,
              I_sreset => sreset_sys_int,
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
              HAVE_BOOTLOADER_ROM => HAVE_BOOTLOADER_ROM,
              ROM_HIGH_NIBBLE => ROM_HIGH_NIBBLE,
              BOOT_HIGH_NIBBLE => BOOT_HIGH_NIBBLE,
              RAM_HIGH_NIBBLE => RAM_HIGH_NIBBLE,
              IO_HIGH_NIBBLE => IO_HIGH_NIBBLE
             )
    port map (              --
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
              ROM_ADDRESS_BITS => ROM_ADDRESS_BITS
             )
    port map (I_clk => clk_int,
              I_areset => areset_sys_int,
              I_sreset => sreset_sys_int,
              -- Fetch instruction
              I_instr_request => instr_request_rom_int,
              O_instr_response => instr_response_rom_int,
              -- Fetch data
              I_mem_request => mem_request_rom_int,
              O_mem_response => mem_response_rom_int
             );

    bootrom0: bootrom
    generic map (
              HAVE_BOOTLOADER_ROM => HAVE_BOOTLOADER_ROM
             )
    port map (I_clk => clk_int,
              I_areset => areset_sys_int,
              I_sreset => sreset_sys_int,
              -- Fetch instruction
              I_instr_request => instr_request_boot_int,
              O_instr_response => instr_response_boot_int,
              -- Fetch  data
              I_mem_request => mem_request_boot_int,
              O_mem_response => mem_response_boot_int
             );
        
    ram0: ram
    generic map (
              RAM_ADDRESS_BITS => RAM_ADDRESS_BITS
             )
    port map (I_clk => clk_int,
              I_areset => areset_sys_int,
              I_sreset => sreset_sys_int,
              -- Fetch data
              I_mem_request => mem_request_ram_int,
              O_mem_response => mem_response_ram_int
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
                  I_sreset => sreset_debug_int,
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
                  I_sreset => sreset_debug_int,
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
        
        dm_core_data_request_int.stb <= '0';
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

    -- I/O bus switch
    io_bus_switch0: io_bus_switch
    generic map (
              -- Extra buffer for I/O response
              BUFFER_IO_RESPONSE  => BUFFER_IO_RESPONSE
             )
    port map (
              I_clk => clk_int,
              I_areset => areset_sys_int,
              I_sreset => sreset_sys_int,
              -- The request
              I_mem_request => mem_request_io_int,
              O_mem_response => mem_response_io_int,
              -- 0x000 - GPIO
              O_dev0_request => gpioa_request_int,
              I_dev0_response => gpioa_response_int,
              -- 0x100 - UARt1
              O_dev1_request => uart1_request_int,
              I_dev1_response => uart1_response_int,
              -- 0x200 - I2C1
              O_dev2_request => i2c1_request_int,
              I_dev2_response => i2c1_response_int,
              -- 0x300 - I2C2
              O_dev3_request => i2c2_request_int,
              I_dev3_response => i2c2_response_int,
              -- 0x400 - SPI1
              O_dev4_request => spi1_request_int,
              I_dev4_response => spi1_response_int,
              -- 0x500 - SPI2
              O_dev5_request => spi2_request_int,
              I_dev5_response => spi2_response_int,
              -- 0x600 - TIMER1
              O_dev6_request => timer1_request_int,
              I_dev6_response => timer1_response_int,
              -- 0x700 - TIMER2
              O_dev7_request => timer2_request_int,
              I_dev7_response => timer2_response_int,
              -- 0x800 - WDT
              O_dev8_request => wdt_request_int,
              I_dev8_response => wdt_response_int,
              -- 0x900 - MSI
              O_dev9_request => msi_request_int,
              I_dev9_response => msi_response_int,
              -- 0xa00 - MTIME
              O_dev10_request => mtime_request_int,
              I_dev10_response => mtime_response_int,
              -- 0xb00 - UART2
              O_dev11_request => uart2_request_int,
              I_dev11_response => uart2_response_int,
              -- 0xc00 - CRC
              O_dev12_request => crc_request_int,
              I_dev12_response => crc_response_int,
              -- 0xd00 - free
              O_dev13_request => stub13_request_int,
              I_dev13_response => stub13_response_int,
              -- 0xe00 - free
              O_dev14_request => stub14_request_int,
              I_dev14_response => stub14_response_int,
              -- 0xf00 - free
              O_dev15_request => stub15_request_int,
              I_dev15_response => stub15_response_int
             );

    -- Always have GPIOA
    gpioa: gpio
    port map (
              I_clk => clk_int,
              I_areset => areset_sys_int,
              I_sreset => sreset_sys_int,
              --
              I_mem_request => gpioa_request_int,
              O_mem_response => gpioa_response_int,
              --
              I_pin => I_gpioapin,
              O_pout => O_gpioapout,
              O_irq => irq_gpioa_int
             );

    -- Always have MTIME
    mtime1 : mtime
    generic map (
              SYSTEM_FREQUENCY => SYSTEM_FREQUENCY,
              CLOCK_FREQUENCY => CLOCK_FREQUENCY
             )
    port map (
              I_clk => clk_int,
              I_areset => areset_sys_int,
              I_sreset => sreset_sys_int,
              --
              I_mem_request => mtime_request_int,
              O_mem_response => mtime_response_int,
              --
              O_mtime => mtime_int,
              O_mtimeh => mtimeh_int,
              O_irq => irq_mtime_int
             );

    -- WDT - watchdog timer
    wdt1gen : if HAVE_WDT generate
        wdt1 : wdt
        port map (
                  I_clk => clk_int,
                  I_areset => areset_sys_int,
                  I_sreset => sreset_sys_int,
                  --
                  I_mem_request => wdt_request_int,
                  O_mem_response => wdt_response_int,
                  --
                  O_reset => reset_from_wdt_int,
                  O_irq => irq_wdt_int
                 );
    end generate;
    wdt1gen_not : if not HAVE_WDT generate
        wdt1 : stub
        port map (
                  I_clk => clk_int,
                  I_areset => areset_sys_int,
                  I_sreset => sreset_sys_int,
                  --
                  I_mem_request => wdt_request_int,
                  O_mem_response => wdt_response_int
                 );
        irq_wdt_int <= '0';
        reset_from_wdt_int <= '0';
    end generate;

    -- MSI - Machine-mode software interruot
    msi1gen : if HAVE_MSI generate
        msi1 : msi
        port map (
                  I_clk => clk_int,
                  I_areset => areset_sys_int,
                  I_sreset => sreset_sys_int,
                  --
                  I_mem_request => msi_request_int,
                  O_mem_response => msi_response_int,
                  --
                  O_irq => irq_msi_int
                 );
    end generate;
    msi1gen_not : if not HAVE_MSI generate
        msi1 : stub
        port map (
                  I_clk => clk_int,
                  I_areset => areset_sys_int,
                  I_sreset => sreset_sys_int,
                  --
                  I_mem_request => msi_request_int,
                  O_mem_response => msi_response_int
                 );
        irq_msi_int <= '0';
    end generate;

    -- TIMER1 - a simple 32-bit timer
    timer1gen : if HAVE_TIMER1 generate
        timer1: timera
        port map (
                  I_clk => clk_int,
                  I_areset => areset_sys_int,
                  I_sreset => sreset_sys_int,
                  --
                  I_mem_request => timer1_request_int,
                  O_mem_response => timer1_response_int,
                  --
                  O_irq => irq_timer1_int
                 );
    end generate;
    timer1gen_not : if not HAVE_TIMER1 generate
        timer1: stub
        port map (
                  I_clk => clk_int,
                  I_areset => areset_sys_int,
                  I_sreset => sreset_sys_int,
                  --
                  I_mem_request => timer1_request_int,
                  O_mem_response => timer1_response_int
                 );
        irq_timer1_int <= '0';
    end generate;

    -- UART1 - an UART for ASCII communication
    uart1gen : if HAVE_UART1 generate
        uart1 : uart
        generic map (
                  UART_BREAK_RESETS => UART1_BREAK_RESETS
                 )
        port map (
                  I_clk => clk_int,
                  I_areset => areset_sys_int,
                  I_sreset => sreset_sys_int,
                  --
                  I_mem_request => uart1_request_int,
                  O_mem_response => uart1_response_int,
                  --
                  I_rxd => I_uart1rxd,
                  O_txd => O_uart1txd,
                  O_break_received => break_from_uart1_int,
                  O_irq => irq_uart1_int
                 );
    end generate;
    uart1gen_not : if not HAVE_UART1 generate
        uart1 : stub
        port map (
                  I_clk => clk_int,
                  I_areset => areset_sys_int,
                  I_sreset => sreset_sys_int,
                  --
                  I_mem_request => uart1_request_int,
                  O_mem_response => uart1_response_int
                 );
        O_uart1txd <= '0';
        break_from_uart1_int <= '0';
        irq_uart1_int <= '0';
    end generate;

    -- I2C1 - A master-only I2C device
    i2c1gen : if HAVE_I2C1 generate
        i2c1 : i2c
        generic map (
                  SYSTEM_FREQUENCY => SYSTEM_FREQUENCY
                 )
        port map (
                  I_clk => clk_int,
                  I_areset => areset_sys_int,
                  I_sreset => sreset_sys_int,
                  --
                  I_mem_request => i2c1_request_int,
                  O_mem_response => i2c1_response_int,
                  --
                  IO_scl => IO_i2c1scl,
                  IO_sda => IO_i2c1sda,
                  O_irq => irq_i2c1_int
                 );
    end generate;
    i2c1gen_not : if not HAVE_I2C1 generate
        i2c1 : stub
        port map (
                  I_clk => clk_int,
                  I_areset => areset_sys_int,
                  I_sreset => sreset_sys_int,
                  --
                  I_mem_request => i2c1_request_int,
                  O_mem_response => i2c1_response_int
                 );
        IO_i2c1scl <= 'Z';
        IO_i2c1sda <= 'Z';
        irq_i2c1_int <= '0';
    end generate;

    -- I2C2 - A master-only I2C device
    i2c2gen : if HAVE_I2C2 generate
        i2c2 : i2c
        generic map (
                  SYSTEM_FREQUENCY => SYSTEM_FREQUENCY
                 )
        port map (
                  I_clk => clk_int,
                  I_areset => areset_sys_int,
                  I_sreset => sreset_sys_int,
                  --
                  I_mem_request => i2c2_request_int,
                  O_mem_response => i2c2_response_int,
                  --
                  IO_scl => IO_i2c2scl,
                  IO_sda => IO_i2c2sda,
                  O_irq => irq_i2c2_int
                 );
    end generate;
    i2c2gen_not : if not HAVE_I2C2 generate
        i2c2 : stub
        port map (
                  I_clk => clk_int,
                  I_areset => areset_sys_int,
                  I_sreset => sreset_sys_int,
                  --
                  I_mem_request => i2c2_request_int,
                  O_mem_response => i2c2_response_int
                 );
        IO_i2c2scl <= 'Z';
        IO_i2c2sda <= 'Z';
        irq_i2c2_int <= '0';
    end generate;

    -- SPI1 - A master-only SPI device
    spi1gen : if HAVE_SPI1 generate
        spi1 : spi
        port map (
                  I_clk => clk_int,
                  I_areset => areset_sys_int,
                  I_sreset => sreset_sys_int,
                  --
                  I_mem_request => spi1_request_int,
                  O_mem_response => spi1_response_int,
                  --
                  O_sck => O_spi1sck,
                  O_mosi => O_spi1mosi,
                  I_miso => I_spi1miso,
                  O_irq => irq_spi1_int
                 );
    end generate;
    spi1gen_not : if not HAVE_SPI1 generate
        spi1 : stub
        port map (
                  I_clk => clk_int,
                  I_areset => areset_sys_int,
                  I_sreset => sreset_sys_int,
                  --
                  I_mem_request => spi1_request_int,
                  O_mem_response => spi1_response_int
                 );
        O_spi1sck <= '0';
        O_spi1mosi <= '0';
        irq_spi1_int <= '0';
    end generate;

    -- SPI2 - A master-only SPI device
    spi2gen : if HAVE_SPI2 generate
        spi2 : spi
        port map (
                  I_clk => clk_int,
                  I_areset => areset_sys_int,
                  I_sreset => sreset_sys_int,
                  --
                  I_mem_request => spi2_request_int,
                  O_mem_response => spi2_response_int,
                  --
                  O_sck => O_spi2sck,
                  O_mosi => O_spi2mosi,
                  I_miso => I_spi2miso,
                  O_irq => irq_spi2_int
                 );
    end generate;
    spi2gen_not : if not HAVE_SPI2 generate
        spi2 : stub
        port map (
                  I_clk => clk_int,
                  I_areset => areset_sys_int,
                  I_sreset => sreset_sys_int,
                  --
                  I_mem_request => spi2_request_int,
                  O_mem_response => spi2_response_int
                 );
        O_spi2sck <= '0';
        O_spi2mosi <= '0';
        irq_spi2_int <= '0';
    end generate;

    -- TIMER2 - A 16-bit timer, with PWM/OC/IC capabilities
    timer2gen : if HAVE_TIMER2 generate
        timer2 : timerb
        port map (
                  I_clk => clk_int,
                  I_areset => areset_sys_int,
                  I_sreset => sreset_sys_int,
                  -- 
                  I_mem_request => timer2_request_int,
                  O_mem_response => timer2_response_int,
                  --
                  O_timeroct => O_timer2oct,
                  IO_timericoca => IO_timer2icoca,
                  IO_timericocb => IO_timer2icocb,
                  IO_timericocc => IO_timer2icocc,
                  O_irq => irq_timer2_int
              );             
    end generate;
    timer2gen_not : if not HAVE_TIMER2 generate
        timer2 : stub
        port map (
                  I_clk => clk_int,
                  I_areset => areset_sys_int,
                  I_sreset => sreset_sys_int,
                  -- 
                  I_mem_request => timer2_request_int,
                  O_mem_response => timer2_response_int
                 );
        O_timer2oct <= '0';
        IO_timer2icoca <= 'Z';
        IO_timer2icocb <= 'Z';
        IO_timer2icocc <= 'Z';
        irq_timer2_int <= '0';
    end generate;

    -- UART2 - an UART for ASCII communication
    uart2gen : if HAVE_UART2 generate
        uart2 : uart
        generic map (
                  UART_BREAK_RESETS => false
                 )
        port map (
                  I_clk => clk_int,
                  I_areset => areset_sys_int,
                  I_sreset => sreset_sys_int,
                  --
                  I_mem_request => uart2_request_int,
                  O_mem_response => uart2_response_int,
                  --
                  I_rxd => I_uart2rxd,
                  O_txd => O_uart2txd,
                  O_break_received => open,
                  O_irq => irq_uart2_int
                 );
    end generate;
    uart2gen_not : if not HAVE_UART2 generate
        uart2 : stub
        port map (
                  I_clk => clk_int,
                  I_areset => areset_sys_int,
                  I_sreset => sreset_sys_int,
                  --
                  I_mem_request => uart2_request_int,
                  O_mem_response => uart2_response_int
                 );
        O_uart2txd <= '0';
        irq_uart2_int <= '0';
    end generate;

    -- CRC
    crcgen : if HAVE_CRC generate
        crc1 : crc
        port map (
                  I_clk => clk_int,
                  I_areset => areset_sys_int,
                  I_sreset => sreset_sys_int,
                  --
                  I_mem_request => crc_request_int,
                  O_mem_response => crc_response_int
                 );
    end generate;
    crcgen_not : if not HAVE_CRC generate
        crc1 : stub
        port map (
                  I_clk => clk_int,
                  I_areset => areset_sys_int,
                  I_sreset => sreset_sys_int,
                  --
                  I_mem_request => crc_request_int,
                  O_mem_response => crc_response_int
                 );
    end generate;

    -- Three stubs for non-used I/O
    stub13gen: stub
    port map (
              I_clk => clk_int,
              I_areset => areset_sys_int,
              I_sreset => sreset_sys_int,
              --
              I_mem_request => stub13_request_int,
              O_mem_response => stub13_response_int
             );
    stub14gen: stub
    port map (
              I_clk => clk_int,
              I_areset => areset_sys_int,
              I_sreset => sreset_sys_int,
              --
              I_mem_request => stub14_request_int,
              O_mem_response => stub14_response_int
             );
    stub15gen: stub
    port map (
              I_clk => clk_int,
              I_areset => areset_sys_int,
              I_sreset => sreset_sys_int,
              --
              I_mem_request => stub15_request_int,
              O_mem_response => stub15_response_int
             );


    -- Bundle all interrupt lines together
    process (irq_gpioa_int, irq_uart1_int, irq_mtime_int, irq_wdt_int,
             irq_msi_int, irq_i2c1_int, irq_i2c2_int, irq_spi1_int,
             irq_spi2_int, irq_timer1_int, irq_timer2_int, irq_uart2_int) is
    begin
        intrio_int <= all_zeros_c;
        
        intrio_int(INTR_PRIO_WDT) <= irq_wdt_int;
        intrio_int(INTR_PRIO_SPI1) <= irq_spi1_int;
        intrio_int(INTR_PRIO_I2C1) <= irq_i2c1_int;
        intrio_int(INTR_PRIO_SPI2) <= irq_spi2_int;
        intrio_int(INTR_PRIO_I2C2) <= irq_i2c2_int;
        intrio_int(INTR_PRIO_UART1) <= irq_uart1_int;
        intrio_int(INTR_PRIO_TIMER1) <= irq_timer1_int;
        intrio_int(INTR_PRIO_TIMER2) <= irq_timer2_int;
        intrio_int(INTR_PRIO_EXTI) <= irq_gpioa_int;
        intrio_int(INTR_PRIO_MTIME) <= irq_mtime_int;
        intrio_int(INTR_PRIO_MSI) <= irq_msi_int;
        intrio_int(INTR_PRIO_UART2) <= irq_uart2_int;
    end process;
 
end architecture rtl;
