-- #################################################################################################
-- # tb_riscv.vhd - Testbench for simulation                                                       #
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

entity tb_riscv is
end entity tb_riscv;

architecture sim of tb_riscv is

-- Component is loaded by processor_common.vhd
signal clk : std_logic;
signal areset : std_logic;
signal trst : std_logic;
signal tck : std_logic;
signal tms : std_logic;
signal tdi : std_logic;
signal tdo : std_logic;
signal gpioapin : data_type;
signal gpioapout : data_type;
signal uart1txd, uart1rxd : std_logic;
signal uart2txd, uart2rxd : std_logic;
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
    dut: riscv
    generic map (
              -- Oscillator at 50 MHz
              SYSTEM_FREQUENCY => 50000000,
              -- Frequency of clock() et al. KEEP THIS TO 1M
              CLOCK_FREQUENCY => 1000000,
              -- Do we have RISC-V embedded (16 registers)?
              HAVE_RISCV_E => false,
              -- Have On-chip debugger?
              HAVE_OCD => false,
              -- Do we have the buildin bootloader?
              HAVE_BOOTLOADER_ROM => false,
              -- Disable CSR address check when in debug mode
              OCD_CSR_CHECK_DISABLE => TRUE,
              -- Do we use post-increment address pointer when debugging?
              OCD_AAMPOSTINCREMENT => TRUE,
              -- Do we have integer hardware multiply/divide?
              HAVE_MULDIV => TRUE,
              -- Do we have the fast divider?
              FAST_DIVIDE => TRUE,
              -- Do we have the Zba extension?
              HAVE_ZBA => false,
              -- Do we have Zbb (bit instructions)?
              HAVE_ZBB => TRUE,
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
              HAVE_UART2 => TRUE,
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
    port map (I_clk => clk,
              I_areset => areset,
              -- JTAG connection
              I_trst => trst,
              I_tck  => tck,
              I_tms  => tms,
              I_tdi  => tdi,
              O_tdo  => tdo,
              -- GPIO
              I_gpioapin => gpioapin,
              O_gpioapout => gpioapout,
              -- UART1
              I_uart1rxd => uart1rxd,
              O_uart1txd => uart1txd,
              -- UART2
              I_uart2rxd => uart2rxd,
              O_uart2txd => uart2txd,
              -- I2C1
              IO_i2c1scl => i2c1scl,
              IO_i2c1sda => i2c1sda,
              -- I2C2
              IO_i2c2scl => i2c2scl,
              IO_i2c2sda => i2c2sda,
              -- SPI1
              O_spi1sck => spi1sck,
              O_spi1mosi => spi1mosi,
              I_spi1miso => spi1miso,
              -- SPI2
              O_spi2sck => spi2sck,
              O_spi2mosi => spi2mosi,
              I_spi2miso => spi2miso,
              -- TIMER2
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
        -- JTAG
        trst <= '1';
        tck <= '0';
        tms <= '0';
        tdi <= '0';
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
        
        -- Send a BREAK condition to UART1
--        for i iN 1 to 12 loop
--            uart1rxd <= '0';
--            wait for bittime;
--        end loop;
        uart1rxd <= '1';
        
        wait;
        
    end process;
    
end architecture sim;
