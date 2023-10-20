-- #################################################################################################
-- # tb_riscv.vhd - Testbench for simulation                                                       #
-- # ********************************************************************************************* #
-- # This file is part of the THUAS RISCV RV32 Project                                             #
-- # ********************************************************************************************* #
-- # BSD 3-Clause License                                                                          #
-- #                                                                                               #
-- # Copyright (c) 2023, Jesse op den Brouw. All rights reserved.                                  #
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
-- # https:/github.com/jesseopdenbrouw/riscv-rv32                                                  #
-- #################################################################################################


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.processor_common.all;

entity tb_riscv is
end entity tb_riscv;

architecture sim of tb_riscv is

--component riscv is
--    generic (
--          -- The frequency of the system
--          SYSTEM_FREQUENCY : integer := 50000000;
--          -- Frequecy of the hardware clock
--          CLOCK_FREQUENCY : integer := 1000000;
--          -- RISCV E (embedded) of RISCV I (full)
--          HAVE_RISCV_E : boolean := false;
--          -- Do we have the integer multiply/divide unit?
--          HAVE_MULDIV : boolean := TRUE;
--          -- Fast divide (needs more area)?
--          FAST_DIVIDE : boolean := TRUE;
--          -- Do we have Zba (sh?add)
--          HAVE_ZBA : boolean := TRUE;
--          -- Do we enable vectored mode for mtvec?
--          VECTORED_MTVEC : boolean := TRUE;
--          -- Do we have registers is RAM?
--          HAVE_REGISTERS_IN_RAM : boolean := TRUE;
--          -- Do we have a bootloader ROM?
--          HAVE_BOOTLOADER_ROM : boolean := TRUE;
--          -- Address width in bits, size is 2**bits
--          ROM_ADDRESS_BITS : integer := 16;
--          -- Address width in bits, size is 2**bits
--          RAM_ADDRESS_BITS : integer := 15;
--          -- Do we have fast store?
--          HAVE_FAST_STORE => boolean := false;
--          -- Do we have UART1?
--          HAVE_UART1 : boolean := TRUE;
--          -- Do we have SPI1?
--          HAVE_SPI1 : boolean := TRUE;
--          -- Do we have SPI2?
--          HAVE_SPI2 : boolean := TRUE;
--          -- Do we have I2C1?
--          HAVE_I2C1 : boolean := TRUE;
--          -- Do we have I2C2?
--          HAVE_I2C2 : boolean := TRUE;
--          -- Do we have TIMER1?
--          HAVE_TIMER1 : boolean := TRUE;
--          -- Do we have TIMER2?
--          HAVE_TIMER2 : boolean := TRUE
--         );
--    port (I_clk : in std_logic;
--          I_areset : in std_logic;
--          -- GPIOA
--          I_gpioapin : in data_type;
--          O_gpioapout : out data_type;
--          -- UART1
--          I_uart1rxd : in std_logic;
--          O_uart1txd : out std_logic;
--          -- I2C1
--          IO_i2c1scl : inout std_logic;
--          IO_i2c1sda : inout std_logic;
--          -- I2C2
--          IO_i2c2scl : inout std_logic;
--          IO_i2c2sda : inout std_logic;
--          -- SPI1
--          O_spi1sck : out std_logic;
--          O_spi1mosi : out std_logic;
--          I_spi1miso : in std_logic;
--          O_spi1nss : out std_logic;
--          -- SPI2
--          O_spi2sck : out std_logic;
--          O_spi2mosi : out std_logic;
--          I_spi2miso : in std_logic;
--          -- TIMER2
--          O_timer2oct : out std_logic;
--          IO_timer2icoca : inout std_logic;
--          IO_timer2icocb : inout std_logic;
--          IO_timer2icocc : inout std_logic
--         );
--end component riscv;

signal clk : std_logic;
signal areset : std_logic;
signal gpioapin : data_type;
signal gpioapout : data_type;
signal uart1txd, uart1rxd : std_logic;
signal timer2oct : std_logic;
signal timer2icoca : std_logic;
signal timer2icocb : std_logic;
signal timer2icocc : std_logic;
signal spi1sck : std_logic;
signal spi1mosi : std_logic;
signal spi1miso : std_logic;
signal spi1nss : std_logic;
signal spi2sck : std_logic;
signal spi2mosi : std_logic;
signal spi2miso : std_logic;
signal i2c1scl : std_logic;
signal i2c1sda : std_logic;
signal i2c2scl : std_logic;
signal i2c2sda : std_logic;

-- Set the bit time
constant bittime : time := (50000000/115200) * 20 ns;
-- Select character to send
constant chartosend : std_logic_vector := "01000001";

begin

    -- Instantiate the processor
    dut : riscv
    generic map (
              -- Oscillator at 50 MHz
              SYSTEM_FREQUENCY => 50000000,
              CLOCK_FREQUENCY => 1000000,
              HAVE_RISCV_E => false,
              HAVE_MULDIV => TRUE,
              FAST_DIVIDE => TRUE,
              HAVE_ZBA => TRUE,
              VECTORED_MTVEC => TRUE,
              HAVE_REGISTERS_IN_RAM => TRUE,
              HAVE_BOOTLOADER_ROM => false,
              HAVE_UART1 => TRUE,
              HAVE_SPI1 => TRUE,
              HAVE_SPI2 => TRUE,
              HAVE_I2C1 => TRUE,
              HAVE_I2C2 => TRUE,
              HAVE_TIMER1 => TRUE,
              HAVE_TIMER2 => TRUE
             )
    port map (I_clk => clk,
              I_areset => areset,
              I_gpioapin => gpioapin,
              O_gpioapout => gpioapout,
              I_uart1rxd => uart1rxd,
              O_uart1txd => uart1txd,
              IO_i2c1scl => i2c1scl,
              IO_i2c1sda => i2c1sda,
              IO_i2c2scl => i2c2scl,
              IO_i2c2sda => i2c2sda,
              O_spi1sck => spi1sck,
              O_spi1mosi => spi1mosi,
              I_spi1miso => spi1miso,
              O_spi1nss => spi1nss,
              O_spi2sck => spi2sck,
              O_spi2mosi => spi2mosi,
              I_spi2miso => spi2miso,
              O_timer2oct => timer2oct,
              IO_timer2icoca => timer2icoca,
              IO_timer2icocb => timer2icocb,
              IO_timer2icocc => timer2icocc
             );
    
    -- Generate a symmetric clock signal, 50 MHz
    process is
    begin
        clk <= '1';
        wait for 10 ns;
        clk <= '0';
        wait for 10 ns;
    end process;
    
    -- Only here to supply a reset, datain and RxD
    -- Reset is active high in design but may be
    -- active low on board
    process is
    begin
        -- Reset is active high
        areset <= '1';
        -- RxD input is idle high
        uart1rxd <= '1';
        gpioapin <= x"ffffff40";
        wait for 15 ns;
        areset <= '0';
        --wait for 40000 ns;
        wait for 23*20 ns;
        gpioapin <= x"ffffff41";
        wait for 100*20 ns;
        --wait for 20000 ns;
        gpioapin <= x"ffffff40";
        
        wait for 500 us;
        
        -- Send start bit
        -- Transmission speed is slightly
        -- faster than 115200 bps
        uart1rxd <= '0';
        wait for bittime;
        -- Send character
        for i in chartosend'high downto 0 loop
            uart1rxd <= chartosend(i);
            wait for bittime;
        end loop;
--        -- Send parity bit
--        RxD <= '0';
--        -- Send stop bit
        wait for bittime;
        uart1rxd <= '1';
        wait for bittime;
        
        wait;
        
    end process;
    
end architecture sim;