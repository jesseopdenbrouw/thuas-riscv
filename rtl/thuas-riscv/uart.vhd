-- #################################################################################################
-- # uart.vhd - Universal Asynchronous Receiver/Transmitter                                        #
-- # ********************************************************************************************* #
-- # This file is part of the THUAS RISCV RV32 Project                                             #
-- # ********************************************************************************************* #
-- # BSD 3-Clause License                                                                          #
-- #                                                                                               #
-- # Copyright (c) 2025, Jesse op den Brouw. All rights reserved.                                  #
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

entity uart is
    generic (
          UART_BREAK_RESETS : boolean
         );
    port (I_clk : in std_logic;
          I_areset : in std_logic;
          -- 
          I_mem_request : in mem_request_type;
          O_mem_response : out mem_response_type;
          --
          I_rxd : in std_logic;
          O_txd: out std_logic;
          O_break_received : out std_logic;
          O_irq : out std_logic
         );
end entity uart;

architecture rtl of uart is

type uart_txstate_type is (tx_idle, tx_iter, tx_ready);
type uart_rxstate_type is (rx_idle, rx_wait, rx_iter, rx_parity, rx_break, rx_ready, rx_fail);

type uart_type is record
    en : std_logic;
    size : std_logic_vector(1 downto 0);
    rcie : std_logic;
    tcie : std_logic;
    brie : std_logic;
    paron : std_logic;
    parnevenodd : std_logic;
    sp2 : std_logic;
    fe : std_logic;
    rf : std_logic;
    pe : std_logic;
    rc : std_logic;
    tc : std_logic;
    br : std_logic;
    data : std_logic_vector(11 downto 0);
    baud : std_logic_vector(15 downto 0);
    -- Transmit signals
    txbuffer : std_logic_vector(10 downto 0);
    txstart : std_logic;
    txstate : uart_txstate_type;
    txbittimer : integer range 0 to 65535;
    txshiftcounter : integer range 0 to 10;
    --Receive signals
    rxbuffer : std_logic_vector(8 downto 0);
    rxstate : uart_rxstate_type;
    rxbittimer : integer range 0 to 65535;
    rxshiftcounter : integer range 0 to 10;
    rxd_sync : std_logic;
end record;

signal uart : uart_type;
signal isword : boolean;
-- For strobing
signal cs_sync : std_logic;

begin

    O_mem_response.load_misaligned_error <= '1' when I_mem_request.cs = '1' and I_mem_request.wren = '0' and I_mem_request.size /= memsize_word else '0';
    O_mem_response.store_misaligned_error <= '1' when I_mem_request.cs = '1' and I_mem_request.wren = '1' and I_mem_request.size /= memsize_word else '0';
    isword <= I_mem_request.size = memsize_word;

    process (I_clk, I_areset) is
    variable uarttxshiftcounter_v : integer range 0 to 15;
    begin
        -- Common resets et al.
        if I_areset = '1' then
            uart.data <= (others => '0');
            uart.baud <= (others => '0');
            uart.en <= '0';
            uart.size <= "00";
            uart.rcie <= '0';
            uart.tcie <= '0';
            uart.brie <= '0';
            uart.paron <= '0';
            uart.sp2 <= '0';
            uart.parnevenodd <= '0';
            uart.fe <= '0';
            uart.rf <= '0';
            uart.pe <= '0';
            uart.rc <= '0';
            uart.tc <= '0';
            uart.br <= '0';
            uart.txstart <= '0';
            uart.txstate <= tx_idle;
            uart.txbuffer <= (others => '0');
            uart.txbittimer <= 0;
            uart.txshiftcounter <= 0;
            uart.rxbuffer <= (others => '0');
            uart.rxstate <= rx_idle;
            uart.rxbittimer <= 0;
            uart.rxshiftcounter <= 0;
            uart.rxd_sync <= '1';
            O_break_received <= '0';
            O_txd <= '1';
            --
            O_mem_response.data <= all_zeros_c;
            O_mem_response.ready <= '0';
            cs_sync <= '0';
        elsif rising_edge(I_clk) then
            O_mem_response.data <= all_zeros_c;
            O_mem_response.ready <= '0';
            cs_sync <= I_mem_request.cs;
            -- Default for start transmission
            uart.txstart <= '0';
            -- Common register writes
            if I_mem_request.cs = '1' and cs_sync = '0' and isword then
                if I_mem_request.wren = '1' then
                    if I_mem_request.addr(3 downto 2) = "00" then
                        -- A write to the control register
                        uart.en <= I_mem_request.data(0);
                        uart.size <= I_mem_request.data(2 downto 1);
                        uart.rcie <= I_mem_request.data(3);
                        uart.tcie <= I_mem_request.data(4);
                        uart.brie <= I_mem_request.data(5);
                        uart.sp2 <= I_mem_request.data(6);
                        uart.parnevenodd <= I_mem_request.data(7);
                        uart.paron <= I_mem_request.data(8);
                    elsif I_mem_request.addr(3 downto 2) = "01" then
                        -- A write to the status register
                        uart.fe <= I_mem_request.data(0);
                        uart.rf <= I_mem_request.data(1);
                        uart.pe <= I_mem_request.data(2);
                        uart.rc <= I_mem_request.data(3);
                        uart.tc <= I_mem_request.data(4);
                        uart.br <= I_mem_request.data(5);
                    elsif I_mem_request.addr(3 downto 2) = "11" then
                        -- A write to the baud rate register
                        -- Use only 16 bits for baud rate
                        uart.baud <= I_mem_request.data(15 downto 0);
                    elsif I_mem_request.addr(3 downto 2) = "10" then
                        -- A write to the data register triggers a transmission
                        -- Signal start
                        uart.txstart <= '1';
                        -- Load transmit buffer with 7/8/9 data bits, parity bit and
                        -- a start bit
                        -- Stop bits will be automatically added since the remaining
                        -- bits are set to 1. Most right bit is start bit.
                        uart.txbuffer <= (others => '1');
                        if uart.size = "10" then
                            -- 9 bits data
                            uart.txbuffer(9 downto 0) <= I_mem_request.data(8 downto 0) & '0';
                            -- Have parity
                            if uart.paron = '1' then
                                uart.txbuffer(10) <= xor_reduce(I_mem_request.data(8 downto 0) & uart.parnevenodd);
                            end if;
                        elsif uart.size = "11" then
                            -- 7 bits data
                            uart.txbuffer(7 downto 0) <= I_mem_request.data(6 downto 0) & '0';
                            -- Have parity
                            if uart.paron = '1' then
                                uart.txbuffer(8) <= xor_reduce(I_mem_request.data(6 downto 0) & uart.parnevenodd);
                            end if;
                        else
                            -- 8 bits data
                            uart.txbuffer(8 downto 0) <= I_mem_request.data(7 downto 0) & '0';
                            -- Have parity
                            if uart.paron = '1' then
                                uart.txbuffer(9) <= xor_reduce(I_mem_request.data(7 downto 0) & uart.parnevenodd);
                            end if;
                        end if;
                        -- Signal that we are sending
                        uart.tc <= '0'; 
                    end if;
                else
                    if I_mem_request.addr(3 downto 2) = "00" then
                        -- Read from control register
                        O_mem_response.data(8 downto 0) <= uart.paron & uart.parnevenodd & uart.sp2 & uart.brie & uart.tcie & uart.rcie & uart.size & uart.en;
                    elsif I_mem_request.addr(3 downto 2) = "01" then
                        -- Read from status register
                        O_mem_response.data(5 downto 0) <= uart.br & uart.tc & uart.rc & uart.pe & uart.rf & uart.fe;
                    elsif I_mem_request.addr(3 downto 2) = "11" then
                        -- Read from baud register
                        O_mem_response.data(15 downto 0) <= uart.baud;
                    elsif I_mem_request.addr(3 downto 2) = "10" then
                        -- Read from data register
                        O_mem_response.data(8 downto 0) <= uart.rxbuffer;
                        -- Clear the received status bits
                        -- BR, PE, RC, RF, FE
                        uart.br <= '0';
                        uart.pe <= '0';
                        uart.rc <= '0';
                        uart.rf <= '0';
                        uart.fe <= '0';
                    end if;
                end if;
                O_mem_response.ready <= '1';
            end if;
            
            -- Transmit a character
            case uart.txstate is
                -- Tx idle state, wait for start
                when tx_idle =>
                    O_txd <= '1';
                    -- If start triggered...
                    if uart.txstart = '1' and uart.en = '1' then
                        -- Load the prescaler, set the number of bits (including start bit)
                        uart.txbittimer <= to_integer(unsigned(uart.baud));
                        if uart.size = "10" then
                            uarttxshiftcounter_v := 10;
                        elsif uart.size = "11" then
                            uarttxshiftcounter_v := 8;
                        else
                            uarttxshiftcounter_v := 9;
                        end if;
                        -- Add up possible parity bit and possible second stop bit
                        if uart.paron = '1' then
                            uarttxshiftcounter_v := uarttxshiftcounter_v + 1;
                        end if;
                        if uart.sp2 = '1' then
                            uarttxshiftcounter_v := uarttxshiftcounter_v + 1;
                        end if;
                        uart.txshiftcounter <= uarttxshiftcounter_v;
                        uart.txstate <= tx_iter;
                    else
                        uart.txstate <= tx_idle;
                    end if;
                -- Transmit the bits
                when tx_iter =>
                    -- Cycle through all bits in the transmit buffer
                    -- First in line is the start bit
                    O_txd <= uart.txbuffer(0);
                    if uart.txbittimer > 0 then
                        uart.txbittimer <= uart.txbittimer - 1;
                    elsif uart.txshiftcounter > 0 then
                        uart.txbittimer <= to_integer(unsigned(uart.baud));
                        uart.txshiftcounter <= uart.txshiftcounter - 1;
                        -- Shift in stop bit
                        uart.txbuffer <= '1' & uart.txbuffer(uart.txbuffer'high downto 1);
                    else
                        uart.txstate <= tx_ready;
                    end if;
                -- Signal ready
                when tx_ready =>
                    O_txd <= '1';
                    uart.txstate <= tx_idle;
                    -- Signal character transmitted
                    uart.tc <= '1'; 
                when others =>
                    O_txd <= '1';
                    uart.txstate <= tx_idle;
            end case;
            
            -- Receive character
            -- Input synchronizer
            uart.rxd_sync <= I_rxd;
            case uart.rxstate is
                -- Rx idle, wait for start bit
                when rx_idle =>
                    -- If detected a start bit ...
                    if uart.rxd_sync = '0'  and uart.en = '1' then
                        -- Set half bit time ...
                        uart.rxbittimer <= to_integer(unsigned(uart.baud))/2;
                        uart.rxstate <= rx_wait;
                    else
                        uart.rxstate <= rx_idle;
                    end if;
                -- Hunt for start bit, check start bit at half bit time
                when rx_wait =>
                    uart.rxbuffer <= (others => '0');
                    if uart.rxbittimer > 0 then
                        uart.rxbittimer <= uart.rxbittimer - 1;
                    else
                        -- At half bit time...
                        -- Start bit is still 0, so continue
                        if uart.rxd_sync = '0' then
                            uart.rxbittimer <= to_integer(unsigned(uart.baud));
                            -- Set reception size
                            if uart.size = "10" then
                                -- 9 bits
                                uart.rxshiftcounter <= 9;
                            elsif uart.size = "11" then
                                -- 7 bits
                                uart.rxshiftcounter <= 7;
                            else
                                -- 8 bits
                                uart.rxshiftcounter <= 8;
                            end if;
                            uart.rxstate <= rx_iter;
                        else
                            -- Start bit is not 0, so invalid transmission
                            uart.rxstate <= rx_fail;
                        end if;
                    end if;
                -- Shift in the data bits
                -- We sample in the middle of a bit time...
                when rx_iter =>
                    if uart.rxbittimer > 0 then
                        -- Bit timer not finished, so keep counting...
                        uart.rxbittimer <= uart.rxbittimer - 1;
                    elsif uart.rxshiftcounter > 0 then
                        -- Bit counter not finished, so restart timer and shift in data bit
                        uart.rxbittimer <= to_integer(unsigned(uart.baud));
                        uart.rxshiftcounter <= uart.rxshiftcounter - 1;
                        if uart.size = "10" then
                            -- 9 bits
                            uart.rxbuffer(8 downto 0) <= uart.rxd_sync & uart.rxbuffer(8 downto 1);
                        elsif uart.size = "11" then
                            -- 7 bits
                            uart.rxbuffer(6 downto 0) <= uart.rxd_sync & uart.rxbuffer(6 downto 1);
                        else
                            -- 8 bits
                            uart.rxbuffer(7 downto 0) <= uart.rxd_sync & uart.rxbuffer(7 downto 1);
                        end if;
                    else
                        -- Do we have a parity bit?
                        if uart.paron = '1' then
                            uart.rxstate <= rx_parity;
                            uart.rxbittimer <= to_integer(unsigned(uart.baud));
                            -- Since all uuper RX bits are zero, we gan generate the parity of the largest data block
                            uart.pe <= xor_reduce(uart.rxbuffer(8 downto 0) & uart.parnevenodd & uart.rxd_sync);
                        else
                            uart.rxstate <= rx_ready;
                        end if;
                    end if;
                -- Wait to middle of stop bit
                when rx_parity =>
                    if uart.rxbittimer > 0 then
                        uart.rxbittimer <= uart.rxbittimer - 1;
                    else
                        uart.rxstate <= rx_ready;
                    end if;
                -- When ready, all bits are shifted in
                -- Even if we use two stop bits, we only check one and
                -- signal reception. This leave some computation time
                -- before the next reception occurs.
                when rx_ready =>
                    -- A 0 at stop bit position and NULL character? then BREAK
                    if uart.rxd_sync = '0' and uart.rxbuffer(8 downto 0) = "000000000" then
                        uart.rxstate <= rx_break;
                    else
                        -- Test for a stray 0 in position of (first) stop bit
                        if uart.rxd_sync = '0' then
                            -- Signal frame error
                            uart.fe <= '1';
                        end if;
                        -- signal reception
                        uart.rc <= '1';
                        uart.rxstate <= rx_idle;
                    end if;
                    -- Anyway, copy the received data to the data register
                    uart.data <= (others => '0');
                    -- Since RX buffer is inititalized to 0's, we can copy in one go
                    uart.data(8 downto 0) <= uart.rxbuffer(8 downto 0);
                -- Test for BREAK release
                when rx_break =>
                    -- If the line is idle again...
                    if uart.rxd_sync = '1' then
                        uart.rxstate <= rx_idle;
                        uart.br <= '1';
                     end if;
                -- Wrong start bit detected, no data present
                when rx_fail =>
                    -- Failed to receive a correct start bit...
                    uart.rxstate <= rx_idle;
                    uart.rf <= '1';
                when others =>
                    uart.rxstate <= rx_idle;
            end case;
            
            -- If a BREAK is received by uart, send this BREAK
            -- upstream to the processor top. BREAK will only
            -- be received when uart is enabled.
            O_break_received <= uart.br and boolean_to_std_logic(UART_BREAK_RESETS);
            
        end if;
    end process;

    O_irq <= '1' when (uart.br = '1' and uart.brie = '1') or
                      (uart.tc = '1' and uart.tcie = '1') or
                      (uart.rc = '1' and uart.rcie = '1') else '0';

end architecture rtl;


