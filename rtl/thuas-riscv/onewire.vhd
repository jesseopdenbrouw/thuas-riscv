-- #################################################################################################
-- # onewire.vhd - Minimal onewire master device                                                   #
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

-- Description of the 1-Wire master-only device. It does not supports
-- enumeration of devices on the bus, so only one slave may be present.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.processor_common.all;

entity onewire is
    generic (
          SYSTEM_FREQUENCY : integer;
          ONEWIRE_FREQUENCY : integer
         );
    port (I_clk : in std_logic;
          I_areset : in std_logic;
          I_sreset : in std_logic;
          -- 
          I_mem_request : in mem_request_type;
          O_mem_response : out mem_response_type;
          --
          IO_dq : inout std_logic;
          O_irq : out std_logic
         );
end entity onewire;

architecture rtl of onewire is

-- Timing constants in micro seconds
constant reset_low_us_c    : integer := 480;
constant reset_wait_us_c   : integer := 960;
constant pres_sample_us_c  : integer := 70;
constant write1_low_us_c   : integer := 6;
constant write0_low_us_c   : integer := 60;
constant rx_sample_us_c    : integer := 15;
constant rx_init_us_c      : integer := 1;
constant recov_us_c        : integer := 1;

-- Convert micro seconds to clock cycles
function us_cycles(us : integer) return integer is
    variable n : natural;
begin
    n := (SYSTEM_FREQUENCY / 1_000_000) * us + ((SYSTEM_FREQUENCY mod 1_000_000) * us + 500_000) / 1_000_000;

    if n = 0 then
        return 1;
    else
        return n;
    end if;
end function;

-- Return number of clock cycles for one slot
function slot_cycles return integer is
begin
    return (SYSTEM_FREQUENCY + ONEWIRE_FREQUENCY / 2) / ONEWIRE_FREQUENCY;
end function;

-- Return maximum of two integers
function maximum(a, b : integer) return integer is
begin
    if a > b then
        return a;
    else
        return b;
    end if;
end function;

-- Timing constants in clock pulses
constant slot_cycles_c : integer := slot_cycles;
constant reset_low_c   : integer := us_cycles(reset_low_us_c);
constant reset_wait_c  : integer := us_cycles(reset_wait_us_c);
constant pres_sample_c : integer := us_cycles(pres_sample_us_c);
constant write1_low_c  : integer := us_cycles(write1_low_us_c);
constant write0_low_c  : integer := us_cycles(write0_low_us_c);
constant rx_sample_c   : integer := us_cycles(rx_sample_us_c);
constant rx_init_c     : integer := us_cycles(rx_init_us_c);
constant recov_c       : integer := us_cycles(recov_us_c);

constant timer_max_c   : integer := maximum(reset_wait_c, slot_cycles_c + recov_c);

-- The states of the state machine
type state_type is (idle, reset_pulse, reset_recovery, tx_slot, rx_bits);

-- Internal data
type onewire_type is record
    state       : state_type;                       -- state of the device
    startwr     : std_logic;                        -- start a transmit operation
    startrv     : std_logic;                        -- start a receive operation
    timer       : natural range 0 to timer_max_c;
    bit_counter : natural range 0 to 7;

    shift_reg   : std_logic_vector(7 downto 0);
    read_reg    : std_logic_vector(7 downto 0);
    drive_low   : std_logic;

    busy        : std_logic;
    tc          : std_logic;                        -- transmit complete
    rc          : std_logic;                        -- receive complete
    pc          : std_logic;                        -- presence search (reset) complete
    tcie        : std_logic;                        -- TC interrupt enable
    rcie        : std_logic;                        -- RC interrupt enable
    pcie        : std_logic;                        -- PC interrupt enable
    reset       : std_logic;                        -- Trigger reset activity
    presence    : std_logic;                        -- 1 = presence
    data        : std_logic_vector(7 downto 0);

    -- Synchronized bus input
    dq_sync1    : std_logic;
    dq_sync2    : std_logic;
end record;
signal onewire : onewire_type;

signal isword : boolean;

begin

    -- Check for one-wire clock frequency
    assert ONEWIRE_FREQUENCY <= 16_300 report "One-wire clock frequency must be lower than or equal to 16.3 kHz" severity warning;

    -- Check for misaligned access
    O_mem_response.load_misaligned_error <= '1' when I_mem_request.stb = '1' and I_mem_request.wren = '0' and I_mem_request.size = memsize_word and I_mem_request.addr(1 downto 0) /= "00" else '0';
    O_mem_response.store_misaligned_error <= '1' when I_mem_request.stb = '1' and I_mem_request.wren = '1' and I_mem_request.size = memsize_word and I_mem_request.addr(1 downto 0) /= "00" else '0';
    -- Check for unsuppored data size
    O_mem_response.load_access_error <= '1' when I_mem_request.stb = '1' and I_mem_request.wren = '0' and I_mem_request.size /= memsize_word else '0';
    O_mem_response.store_access_error <= '1' when I_mem_request.stb = '1' and I_mem_request.wren = '1' and I_mem_request.size /= memsize_word  else '0';
    
    -- Correct size and address boundary
    isword <= I_mem_request.size = memsize_word and I_mem_request.addr(1 downto 0) = "00";
    

    -- Synchronize the bus input
    process (I_clk, I_areset) is
    begin
        if I_areset = '1' then
            onewire.dq_sync1 <= '1';
            onewire.dq_sync2 <= '1';
        elsif rising_edge(I_clk) then
            if I_sreset = '1' then
                onewire.dq_sync1 <= '1';
                onewire.dq_sync2 <= '1';
            else
                onewire.dq_sync1 <= IO_dq;
                onewire.dq_sync2 <= onewire.dq_sync1;
            end if;
        end if;
    end process;

    process (I_clk, I_areset) is
    variable low_time : integer range 0 to maximum(write0_low_c, write1_low_c);
    begin
        if I_areset = '1' then
            onewire.state <= idle;
            onewire.startwr <= '0';
            onewire.startrv <= '0';
            onewire.timer <= 0;
            onewire.bit_counter <= 0;
            onewire.shift_reg <= (others => '0');
            onewire.read_reg <= (others => '0');
            onewire.data <= (others => '0');
            onewire.drive_low <= '0';
            onewire.busy <= '0';
            onewire.tc <= '0';
            onewire.rc <= '0';
            onewire.pc <= '0';
            onewire.tcie <= '0';
            onewire.rcie <= '0';
            onewire.pcie <= '0';
            onewire.reset <= '0';
            onewire.presence <= '0';
            --
            O_mem_response.data <= all_zeros_c;
            O_mem_response.ready <= '0';
        elsif rising_edge(I_clk) then
            O_mem_response.data <= all_zeros_c;
            O_mem_response.ready <= '0';

            if I_sreset = '1' then
                onewire.state <= idle;
                onewire.startwr <= '0';
                onewire.startrv <= '0';
                onewire.timer <= 0;
                onewire.bit_counter <= 0;
                onewire.shift_reg <= (others => '0');
                onewire.read_reg <= (others => '0');
                onewire.data <= (others => '0');
                onewire.drive_low <= '0';
                onewire.busy <= '0';
                onewire.tc <= '0';
                onewire.rc <= '0';
                onewire.pc <= '0';
                onewire.tcie <= '0';
                onewire.rcie <= '0';
                onewire.pcie <= '0';
                onewire.reset <= '0';
                onewire.presence <= '0';
            else
                if I_mem_request.stb = '1' and isword then
                    -- Common register writes
                    if I_mem_request.wren = '1' then
                        if I_mem_request.addr(3 downto 2) = "00" then
                            -- Write control register
                            onewire.rcie <= I_mem_request.data(3);
                            onewire.tcie <= I_mem_request.data(4);
                            onewire.pcie <= I_mem_request.data(5);
                            -- This bit is auto-clear after function is complete
                            onewire.reset <= I_mem_request.data(6);
                            if I_mem_request.data(6) = '1' then
                                onewire.pc <= '0';
                            end if;
                        elsif I_mem_request.addr(3 downto 2) = "01" then
                            -- Write status register
                            onewire.rc <= I_mem_request.data(3);
                            onewire.tc <= I_mem_request.data(4);
                            onewire.pc <= I_mem_request.data(5);
                            onewire.presence <= I_mem_request.data(6);
                            onewire.busy <= I_mem_request.data(7);
                        elsif I_mem_request.addr(3 downto 2) = "10" then
                            -- Write data register: start a transmission
                            onewire.shift_reg <= I_mem_request.data(7 downto 0);
                            onewire.startwr <= '1';
                            onewire.tc <= '0';
                            onewire.pc <= '0';
                        elsif I_mem_request.addr(3 downto 2) = "11" then
                            -- Start a reception
                            onewire.startrv <= '1';
                            onewire.rc <= '0';
                            onewire.pc <= '0';
                        end if;
                    -- Common register reads
                    else
                        if I_mem_request.addr(3 downto 2) = "00" then
                            O_mem_response.data(3) <= onewire.rcie;
                            O_mem_response.data(4) <= onewire.tcie;
                            O_mem_response.data(6) <= onewire.reset;
                        elsif I_mem_request.addr(3 downto 2) = "01" then
                            O_mem_response.data(3) <= onewire.rc;
                            O_mem_response.data(4) <= onewire.tc;
                            O_mem_response.data(5) <= onewire.pc;
                            O_mem_response.data(6) <= onewire.presence;
                            O_mem_response.data(7) <= onewire.busy;
                        elsif I_mem_request.addr(3 downto 2) = "10" then
                            -- Copy data
                            O_mem_response.data(7 downto 0) <= onewire.data;
                            onewire.rc <= '0';
                        elsif I_mem_request.addr(3 downto 2) = "11" then
                            -- This reads all-zero bits
                            null;
                        end if;
                    end if;
                    O_mem_response.ready <= '1';
                end if; -- stb


                -- The one-wire master state machine
                case onewire.state is
                    -- Idle state: wait for command
                    when idle =>
                        onewire.drive_low <= '0';
                        onewire.busy      <= '0';
                        onewire.timer     <= 0;

                        -- Explicit byte transmission, LSB first
                        if onewire.startwr = '1' then
                            onewire.startwr <= '0';
                            onewire.busy <= '1';
                            onewire.bit_counter <= 0;
                            onewire.drive_low <= '1';
                            onewire.timer <= 0;
                            onewire.state <= tx_slot;
                       -- Reset and presence detection
                        elsif onewire.reset = '1' then
                            -- Auto-clear the reset bit
                            onewire.reset <= '0';
                            onewire.busy <= '1';
                            onewire.presence <= '0';
                            onewire.drive_low <= '1';
                            onewire.timer <= 0;
                            onewire.state <= reset_pulse;
                        -- Start reception
                        elsif onewire.startrv = '1' then
                            onewire.startrv <= '0';
                            onewire.read_reg  <= (others => '0');
                            onewire.bit_counter <= 0;
                            onewire.timer <= 0;
                            onewire.busy <= '1';
                            -- Drive the data line low
                            onewire.drive_low <= '1';
                            onewire.state <= rx_bits;
                        end if;

                    -- Send out reset pulse
                    when reset_pulse =>
                        onewire.drive_low <= '1';

                        if onewire.timer = reset_low_c - 1 then
                            onewire.drive_low <= '0';
                            onewire.timer <= 0;
                            onewire.state <= reset_recovery;
                        else
                            onewire.timer <= onewire.timer + 1;
                        end if;

                    -- Wait for presence signal
                    when reset_recovery =>
                        onewire.drive_low <= '0';

                        if onewire.timer = pres_sample_c - 1 then
                            onewire.presence <= not onewire.dq_sync2;
                        end if;

                        if onewire.timer = reset_wait_c - 1 then
                            onewire.timer <= 0;
                            onewire.busy <= '0';
                            onewire.pc <= '1';
                            onewire.state <= idle;
                        else
                            onewire.timer <= onewire.timer + 1;
                        end if;

                    -- Transmit one byte, LSB first
                    when tx_slot =>
                        if onewire.shift_reg(0) = '1' then
                            low_time := write1_low_c;
                        else
                            low_time := write0_low_c;
                        end if;

                        if onewire.timer = low_time - 1 then
                            onewire.drive_low <= '0';
                        end if;

                        if onewire.timer = slot_cycles_c + recov_c - 1 then
                            if onewire.bit_counter = 7 then
                                onewire.drive_low <= '0';
                                onewire.timer <= 0;
                                onewire.busy <= '0';
                                onewire.tc <= '1';
                                onewire.state <= idle;
                            else
                                onewire.bit_counter <= onewire.bit_counter + 1;
                                onewire.shift_reg <= '0' & onewire.shift_reg(7 downto 1);
                                onewire.drive_low <= '1';
                                onewire.timer <= 0;
                            end if;
                        else
                            onewire.timer <= onewire.timer + 1;
                        end if;

                    -- Receive eight externally transmitted bits.
                    -- Sample each bit at rx_sample_c after its falling edge.
                    when rx_bits =>

                        -- Generate a start for read
                        if onewire.timer = rx_init_c then
                            onewire.drive_low <= '0';
                        end if;
                        
                        -- Sample the data line
                        if onewire.timer = rx_sample_c - 1 then
                            onewire.read_reg <= onewire.dq_sync2 & onewire.read_reg(7 downto 1);
                        end if;

                        -- Slot time and recovery time
                        if onewire.timer = slot_cycles_c + recov_c - 1 then
                            if onewire.bit_counter = 7 then
                                onewire.timer <= 0;
                                onewire.busy <= '0';
                                onewire.rc <= '1';
                                onewire.state <= idle;
                                onewire.data <= onewire.read_reg;
                            else 
                                onewire.bit_counter <= onewire.bit_counter + 1;
                                onewire.timer <= 0;
                                onewire.drive_low <= '1';
                            end if;
                        else
                            onewire.timer <= onewire.timer + 1;
                        end if;

                    when others =>
                        null;
                end case;


            end if; -- sreset
        end if; -- posedge
    end process;        
    
    -- Open-drain bus interface. An external pull-up is required.
    IO_dq <= '0' when onewire.drive_low = '1' else 'Z';
    -- Generate IRQ
    O_irq <= (onewire.tcie and onewire.tc) or (onewire.rcie and onewire.rc) or (onewire.pcie and onewire.pc);
    
end architecture rtl;
