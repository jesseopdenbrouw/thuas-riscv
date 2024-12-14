-- #################################################################################################
-- # de0_cv.vhd - top level description for Terasic DE0-CV board.                                  #
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


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.processor_common.all;

entity de0_cv is
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
end entity de0_cv;

architecture toplevel of de0_cv is

signal areset_int : std_logic;

begin
    -- Reset button of DE0-CV is active low
    areset_int <= not I_areset;

    riscv0: riscv
    generic map (
              -- Oscillator at 50 MHz
              SYSTEM_FREQUENCY => 50000000,
              -- Frequency of clock() et al. KEEP THIS TO 1M
              CLOCK_FREQUENCY => 1000000,
              -- Do we have RISC-V embedded (16 registers)?
              HAVE_RISCV_E => false,
              -- Have On-chip debugger?
              HAVE_OCD => TRUE,
              -- Do we have the buildin bootloader?
              HAVE_BOOTLOADER_ROM => false,
              -- Disable CSR address check when in debug mode
              OCD_CSR_CHECK_DISABLE => false,
              -- Do we use post-increment address pointer when debugging?
              OCD_AAMPOSTINCREMENT => TRUE,
              -- Do we have integer hardware multiply/divide?
              HAVE_MULDIV => TRUE,
              -- Do we have the fast divider?
              FAST_DIVIDE => false,
              -- Do we have the Zba extension?
              HAVE_ZBA => false,
              -- Do we have Zbs (bit instructions)?
              HAVE_ZBS => false,
              -- Do we have Zicond (czero.{eqz|nez})?
              HAVE_ZICOND => false,
              -- Do we have HPM counters?
              HAVE_ZIHPM => false,
              -- Do we have vectored MTVEC (for interrupts)?
              VECTORED_MTVEC => TRUE,
              -- Do we have registers in onboard RAM?
              HAVE_REGISTERS_IN_RAM => TRUE,
              -- Number of address bits for ROM
              ROM_ADDRESS_BITS => 16,
              -- Number of address bits for RAM
              RAM_ADDRESS_BITS => 15,
              -- 4 high bits of ROM address
              ROM_HIGH_NIBBLE => x"0",
              -- 4 high bits of boot ROM address
              BOOT_HIGH_NIBBLE => x"1",
              -- 4 high bits of RAM address
              RAM_HIGH_NIBBLE => x"2",
              -- 4 high bits of I/O address
              IO_HIGH_NIBBLE => x"F",
              -- Buffer I/O response
              BUFFER_IO_RESPONSE => false,
              -- Use UART1?
              HAVE_UART1 => TRUE,
              -- Use UART2?
              HAVE_UART2 => false,
              -- Use SPI1?
              HAVE_SPI1 => TRUE,
              -- Use SPI2?
              HAVE_SPI2 => TRUE,
              -- Use I2C1?
              HAVE_I2C1 => TRUE,
              -- Use I2C2?
              HAVE_I2C2 => TRUE,
              -- Use Timer 1?
              HAVE_TIMER1 => TRUE,
              -- Use Timer 2?
              HAVE_TIMER2 => TRUE,
              -- Use Machine-mode Software Interrupt?
              HAVE_MSI => TRUE,
              -- Use watchdog?
              HAVE_WDT => TRUE,
              -- UART1 BREAK triggers system reset
              UART1_BREAK_RESETS => false
             )
    port map (I_clk => I_clk,
              I_areset => areset_int,
              -- JTAG connection
              I_trst => I_trst,
              I_tck  => I_tck,
              I_tms  => I_tms,
              I_tdi  => I_tdi,
              O_tdo  => O_tdo,
              -- GPIO
              I_gpioapin => I_gpioapin,
              O_gpioapout => O_gpioapout,
              -- UART1
              I_uart1rxd => I_uart1rxd,
              O_uart1txd => O_uart1txd,
              -- UART2
              I_uart2rxd => I_uart2rxd,
              O_uart2txd => O_uart2txd,
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
              IO_timer2icocc => IO_timer2icocc
            );
end architecture toplevel;
