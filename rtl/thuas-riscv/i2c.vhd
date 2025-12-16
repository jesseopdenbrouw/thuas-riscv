-- #################################################################################################
-- # i2c.vhd - Minimal I2C device, master only                                                     #
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

-- Description of the I2C master-only device. The device supports Standard Mode and Fast Mode.
-- It supports clock stretching. It does not support clock synchronization and arbitration lost.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.processor_common.all;

entity i2c is
    generic (
          SYSTEM_FREQUENCY : integer
         );
    port (I_clk : in std_logic;
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
end entity i2c;

architecture rtl of i2c is

-- Calculate maximum rise time for Sm and Fm, add +2 to compensate for synchronizer delay
constant crise_sm_c : integer := SYSTEM_FREQUENCY / 1000000 + 2;
constant crise_fm_c : integer := 300 * (SYSTEM_FREQUENCY / 1000000) / 1000 + 2;

-- States for the state machine
type i2cstate_type is (idle, send_startbit, send_data_first, send_data_second,
                       send_stopbit_first, send_stopbit_second, send_stopbit_third,
                       stretch);
                        
type i2c_type is record
    fm : std_logic;
    tcie : std_logic;
    stop : std_logic;
    start : std_logic;
    hardstop : std_logic;
    mack : std_logic;
    trans : std_logic;
    tc : std_logic;
    af : std_logic;
    busy : std_logic;
    baud : std_logic_vector(15 downto 0);
    data : std_logic_vector(7 downto 0);
    --
    state : i2cstate_type;
    bittimer : integer range 0 to 2**17-1;
    shiftcounter : integer range 0 to 9;
    starttransmission : std_logic;
    txbuffer : std_logic_vector(8 downto 0);
    rxbuffer : std_logic_vector(8 downto 0);
    sda_out : std_logic;
    scl_out : std_logic;
    sdasync : std_logic_vector(1 downto 0);
    sclsync : std_logic_vector(1 downto 0);
    trise : integer range 0 to crise_sm_c;
end record;

signal i2c : i2c_type;
signal isword : boolean;
-- For strobing
signal cs_sync : std_logic;

begin

    O_mem_response.load_misaligned_error <= '1' when I_mem_request.stb = '1' and I_mem_request.wren = '0' and (I_mem_request.size /= memsize_word or I_mem_request.addr(1 downto 0) /= "00") else '0';
    O_mem_response.store_misaligned_error <= '1' when I_mem_request.stb = '1' and I_mem_request.wren = '1' and (I_mem_request.size /= memsize_word  or I_mem_request.addr(1 downto 0) /= "00") else '0';
    isword <= I_mem_request.size = memsize_word and I_mem_request.addr(1 downto 0) = "00" ;
    
    process (I_clk, I_areset) is
    begin
        if I_areset = '1' then
            i2c.fm <= '0';
            i2c.tcie <= '0';
            i2c.stop <= '0';
            i2c.start <= '0';
            i2c.hardstop <= '0';
            i2c.mack <= '0';
            i2c.baud <= (others => '0');
            i2c.trans <= '0';
            i2c.tc <= '0';
            i2c.af <= '0';
            i2c.busy <= '0';
            i2c.data <= (others => '0');
            i2c.scl_out <= '1';
            i2c.sda_out <= '1';
            i2c.state <= idle;
            i2c.bittimer <= 0;
            i2c.shiftcounter <= 0;
            i2c.txbuffer <= (others => '0');
            i2c.rxbuffer <= (others => '0');
            i2c.starttransmission <= '0';
            i2c.sclsync <= (others => '1');
            i2c.sdasync <= (others => '1');
            i2c.trise <= 0;
            --
            O_mem_response.data <= all_zeros_c;
            O_mem_response.ready <= '0';

        elsif rising_edge(I_clk) then
            O_mem_response.data <= all_zeros_c;
            O_mem_response.ready <= '0';
            i2c.starttransmission <= '0';
            
            if I_sreset = '1' then
                i2c.fm <= '0';
                i2c.tcie <= '0';
                i2c.stop <= '0';
                i2c.start <= '0';
                i2c.hardstop <= '0';
                i2c.mack <= '0';
                i2c.baud <= (others => '0');
                i2c.trans <= '0';
                i2c.tc <= '0';
                i2c.af <= '0';
                i2c.busy <= '0';
                i2c.data <= (others => '0');
                i2c.scl_out <= '1';
                i2c.sda_out <= '1';
                i2c.state <= idle;
                i2c.bittimer <= 0;
                i2c.shiftcounter <= 0;
                i2c.txbuffer <= (others => '0');
                i2c.rxbuffer <= (others => '0');
                i2c.sclsync <= (others => '1');
                i2c.sdasync <= (others => '1');
                i2c.trise <= 0;
            else
                -- Common register writes
                if I_mem_request.stb = '1' and isword then
                    if I_mem_request.wren = '1' then
                        if I_mem_request.addr(3 downto 2) = "00" then
                            -- Write control register
                            i2c.fm <= I_mem_request.data(2);
                            i2c.tcie <= I_mem_request.data(3);
                            i2c.stop <= I_mem_request.data(8);
                            i2c.start <= I_mem_request.data(9);
                            i2c.hardstop <= I_mem_request.data(10);
                            i2c.mack <= I_mem_request.data(11);
                            i2c.baud <= I_mem_request.data(31 downto 16);
                        elsif I_mem_request.addr(3 downto 2) = "01" then
                            -- Write status register
                            i2c.trans <= I_mem_request.data(2);
                            i2c.tc <= I_mem_request.data(3);
                            i2c.af <= I_mem_request.data(5);
                            i2c.busy <= I_mem_request.data(6);
                        elsif I_mem_request.addr(3 downto 2) = "10" then
                            -- Latch data, if startbit set, end with master Nack
                            i2c.txbuffer <= I_mem_request.data(7 downto 0) & (i2c.start or i2c.stop or not i2c.mack);
                            -- Signal that we are sending data
                            i2c.starttransmission <= '1';
                            -- Reset both Transmission Complete and Ack Failed
                            i2c.tc <= '0';
                            i2c.af <= '0';
                        end if;
                    else
                        if I_mem_request.addr(3 downto 2) = "00" then
                            -- Read control register
                            O_mem_response.data(2) <= i2c.fm;
                            O_mem_response.data(3) <= i2c.tcie;
                            O_mem_response.data(8) <= i2c.stop;
                            O_mem_response.data(9) <= i2c.start;
                            O_mem_response.data(10) <= i2c.hardstop;
                            O_mem_response.data(11) <= i2c.mack;
                            O_mem_response.data(31 downto 16) <= i2c.baud;
                        elsif I_mem_request.addr(3 downto 2) = "01" then
                            -- Read status register
                            O_mem_response.data(2) <= i2c.trans;
                            O_mem_response.data(3) <= i2c.tc;
                            O_mem_response.data(5) <= i2c.af;
                            O_mem_response.data(6) <= i2c.busy;
                        elsif I_mem_request.addr(3 downto 2) = "10" then
                            -- Read data register
                            O_mem_response.data(7 downto 0) <= i2c.data(7 downto 0);
                            -- Reset flags
                            i2c.tc <= '0';
                            i2c.af <= '0';
                        end if;
                    end if;
                    O_mem_response.ready <= '1';
                end if;

                -- Check for I2C bus is busy.
                -- If SCL or SDA is/are low...
                if i2c.sclsync(1) = '0' or i2c.sdasync(1) = '0' then
                    -- I2C bus is busy
                    i2c.busy <= '1';
                end if;
                -- SCL is high and rising edge on SDA...
                if i2c.sclsync(0) /= '0' and i2c.sdasync(1) = '0' and i2c.sdasync(0) /= '0' then
                    -- signals a STOP, so bus is free
                    i2c.busy <= '0';
                end if;
                
                -- Input synchronizer
                i2c.sdasync <= i2c.sdasync(0) & IO_sda;
                i2c.sclsync <= i2c.sclsync(0) & IO_scl;

                -- The i2c state machine
                case i2c.state is
                    when idle =>
                        -- Clock == !state_of_transmitting, SDA = High-Z (==1)
                        -- If transmitting, the clock is held low. If not
                        -- transmitting, the clock is held high (high-Z). After
                        -- STOP, the state of transmitting is reset. This keeps
                        -- the bus occupied between START and STOP.
                        i2c.scl_out <= not i2c.trans;
                        i2c.sda_out <= '1';
                        -- Idle situation, load the counters and set SCL/SDA to High-Z
                        if i2c.fm = '1' then
                            i2c.bittimer <= to_integer(unsigned(i2c.baud))*2;
                        else
                            i2c.bittimer <= to_integer(unsigned(i2c.baud));
                        end if;
                        i2c.shiftcounter <= 8;
                        -- Is data register written?
                        if i2c.starttransmission = '1' then
                            -- Register that we are transmitting
                            i2c.trans <= '1';
                            -- Data written to data register, check for start condition
                            if i2c.start = '1' then
                                -- Start bit is seen, so clear it.
                                i2c.start <= '0';
                                -- Send a START bit, so address comes next
                                i2c.state <= send_startbit;
                            else
                                -- Regular data
                                i2c.state <= send_data_first;
                            end if;
                        -- Do we have to send a single STOP condition?
                        elsif i2c.hardstop = '1' then
                            i2c.state <= send_stopbit_first;
                        end if;
                    when send_startbit =>
                        -- Generate start condition
                        i2c.scl_out <= '1';
                        i2c.sda_out <= '0';
                        if i2c.bittimer > 0 then
                            i2c.bittimer <= i2c.bittimer - 1;
                        else
                            if i2c.fm = '1' then
                                i2c.bittimer <= to_integer(unsigned(i2c.baud))*2;
                            else
                                i2c.bittimer <= to_integer(unsigned(i2c.baud));
                            end if;
                            i2c.state <= send_data_first;
                        end if;
                    when send_data_first =>
                        -- SCL low == 0, SDA 0 or High-Z (== 1)
                        i2c.scl_out <= '0';
                        i2c.sda_out <= i2c.txbuffer(8);
                        
                        -- Count bit time
                        if i2c.bittimer > 0 then
                            i2c.bittimer <= i2c.bittimer - 1;
                        else
                            i2c.bittimer <= to_integer(unsigned(i2c.baud));
                            i2c.state <= send_data_second;
                            -- Set the rise time of SCL in clock pulses
                            if i2c.fm = '1' then
                                i2c.trise <= crise_fm_c;
                            else
                                i2c.trise <= crise_sm_c;
                            end if;
                        end if;
                    when send_data_second =>
                        -- SCL High-Z == 1, SDA 0 or High-Z (== 1)
                        i2c.scl_out <= '1';
                        i2c.sda_out <= i2c.txbuffer(8);

                        -- Count down rise time
                        if i2c.trise  > 0 then
                            i2c.trise  <= i2c.trise - 1;
                        else
                            -- Check for SCL low == clock stretched
                            if i2c.sclsync(1) = '0' then
                                i2c.state <= stretch;
                            end if;
                        end if;
                        
                        -- Count bit time
                        if i2c.bittimer > 0 then
                            i2c.bittimer <= i2c.bittimer - 1;
                        else
                            if i2c.fm = '1' then
                                i2c.bittimer <= to_integer(unsigned(i2c.baud))*2;
                            else
                                i2c.bittimer <= to_integer(unsigned(i2c.baud));
                            end if;
                            -- Check if more bits
                            if i2c.shiftcounter > 0 then
                                -- More bits to send...
                                i2c.shiftcounter <= i2c.shiftcounter - 1;
                                i2c.state <= send_data_first;
                                -- Shift next bit, hold time is 0 ns as per spec
                                i2c.txbuffer <= i2c.txbuffer(7 downto 0) & '1';
                            else
                                -- No more bits, then goto STOP or leadout
                                if i2c.stop = '1' then
                                    i2c.state <= send_stopbit_first;
                                else
                                    i2c.state <= idle;
                                    i2c.tc <= '1';
                                    i2c.data <= i2c.rxbuffer(8 downto 1);
                                    i2c.af <= i2c.rxbuffer(0);
                                    --i2c.state <= leadout;
                                end if;
                            end if;
                        end if;
                        -- If detected rising edge on external SCL, clock in SDA.
                        if i2c.sclsync(1) = '0' and i2c.sclsync(0) /= '0' then
                            i2c.rxbuffer <= i2c.rxbuffer(7 downto 0) & i2c.sdasync(1);
                        end if;
                    when send_stopbit_first =>
                        -- SCL low, SDA low
                        i2c.scl_out <= '0';
                        i2c.sda_out <= '0';
                        -- Count bit time
                        if i2c.bittimer > 0 then
                            i2c.bittimer <= i2c.bittimer - 1;
                        else
                            i2c.bittimer <= to_integer(unsigned(i2c.baud));
                            i2c.state <= send_stopbit_second;
                        end if;
                    when send_stopbit_second =>
                        -- SCL high, SDA low
                        i2c.scl_out <= '1';
                        i2c.sda_out <= '0';
                        -- Count bit timer
                        if i2c.bittimer > 0 then
                            i2c.bittimer <= i2c.bittimer - 1;
                        else
                            if i2c.fm = '1' then
                                i2c.bittimer <= to_integer(unsigned(i2c.baud))*2;
                            else
                                i2c.bittimer <= to_integer(unsigned(i2c.baud));
                            end if;
                            i2c.state <= send_stopbit_third;
                        end if;
                    when send_stopbit_third =>
                        -- SCL high, SDA high
                        i2c.scl_out <= '1';
                        i2c.sda_out <= '1';
                        -- Count bit timer
                        if i2c.bittimer > 0 then
                            i2c.bittimer <= i2c.bittimer - 1;
                        else
                            -- Transmission conplete
                            i2c.tc <= '1';
                            -- Clear STOP bit
                            i2c.stop <= '0';
                            -- and goto IDLE
                            i2c.state <= idle;
                            -- Copy data to data register and flag ACK
                            i2c.data <= i2c.rxbuffer(8 downto 1);
                            i2c.af <= i2c.rxbuffer(0);
                            -- Clear hard stop
                            i2c.hardstop <= '0';
                            -- Unregister that we are transmitting
                            i2c.trans <= '0';
                        end if;
                    when stretch =>
                        -- Clock is stretched
                        -- Load bit time for high perriod
                        i2c.bittimer <= to_integer(unsigned(i2c.baud));
                        -- Set the rise time of SCL in clock pulses
                        if i2c.fm = '1' then
                            i2c.trise <= crise_fm_c;
                        else
                            i2c.trise <= crise_sm_c;
                        end if;
                        -- Check if SCL is released...
                        if i2c.sclsync(1) /= '0' then
                            -- Resume transmission
                            i2c.state <= send_data_second;
                        end if;
                        -- If detected rising edge on external SCL, clock in SDA.
                        if i2c.sclsync(1) = '0' and i2c.sclsync(0) /= '0' then
                            i2c.rxbuffer <= i2c.rxbuffer(7 downto 0) & i2c.sdasync(1);
                        end if;
                    when others =>
                        i2c.state <= idle;
                end case;
            end if; -- sreset
        end if; -- posedge
    end process;
    -- Drive the clock and data lines
    IO_scl <= '0' when i2c.scl_out = '0' else 'Z';
    IO_sda <= '0' when i2c.sda_out = '0' else 'Z';
    O_irq <= i2c.tcie and i2c.tc;
    

end architecture rtl;