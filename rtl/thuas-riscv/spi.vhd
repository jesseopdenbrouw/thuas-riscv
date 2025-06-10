-- #################################################################################################
-- # spi.vhd - Serial Pheripheral Interface                                                        #
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

entity spi is
    port (I_clk : in std_logic;
          I_areset : in std_logic;
          -- 
          I_mem_request : in mem_request_type;
          O_mem_response : out mem_response_type;
          --
          O_sck : out std_logic;
          O_mosi : out std_logic;
          I_miso : in std_logic;
          O_irq : out std_logic
         );
end entity spi;

architecture rtl of spi is

type spistate_type is (idle, first, second, leadout);

type spi_type is record
    cpha : std_logic;
    cpol : std_logic;
    tcie : std_logic;
    size : std_logic_vector(1 downto 0);
    prescaler : std_logic_vector(2 downto 0);
    tc : std_logic;
    data : data_type;
    --
    start : std_logic;
    state : spistate_type;
    txbuffer : data_type;
    rxbuffer : data_type;
    bittimer : integer range 0 to 127;
    shiftcounter : integer range 0 to 32;
    mosi : std_logic;
    sck : std_logic;
end record;

signal spi : spi_type;
signal isword : boolean;
constant spimosidefault : std_logic := '1';
-- For strobing
signal cs_sync : std_logic;

begin

    O_mem_response.load_misaligned_error <= '1' when I_mem_request.cs = '1' and I_mem_request.wren = '0' and (I_mem_request.size /= memsize_word or I_mem_request.addr(1 downto 0) /= "00") else '0';
    O_mem_response.store_misaligned_error <= '1' when I_mem_request.cs = '1' and I_mem_request.wren = '1' and (I_mem_request.size /= memsize_word  or I_mem_request.addr(1 downto 0) /= "00") else '0';
    isword <= I_mem_request.size = memsize_word and I_mem_request.addr(1 downto 0) = "00" ;
    
    process (I_clk, I_areset) is
    variable spiprescaler_v : integer range 0 to 255;
    begin
        -- Common resets et al.
        if I_areset = '1' then
            spi.cpha <= '0';
            spi.cpol <= '0';
            spi.tcie <= '0';
            spi.size <= (others => '0');
            spi.prescaler <= (others => '0');
            spi.tc <= '0';
            spi.data <= (others => '0');
            --
            spi.start <= '0';
            spi.state <= idle;
            spi.txbuffer <= (others => '0');
            spi.bittimer <= 0;
            spi.shiftcounter <= 0;
            spi.mosi <= spimosidefault;
            spi.rxbuffer <= (others => '0');
            spi.sck <= '0';
            --
            O_mem_response.data <= all_zeros_c;
            O_mem_response.ready <= '0';
            cs_sync <= '0';            
        elsif rising_edge(I_clk) then
            O_mem_response.data <= all_zeros_c;
            O_mem_response.ready <= '0';
            cs_sync <= I_mem_request.cs;            
            -- Default for start transmission
            spi.start <= '0';
            -- Common register writes
            if I_mem_request.cs = '1' and cs_sync = '0' and isword then
                if I_mem_request.wren = '1' then
                    if I_mem_request.addr(3 downto 2) = "00" then
                        -- A write to the control register
                        spi.cpha <= I_mem_request.data(1);
                        spi.cpol <= I_mem_request.data(2);
                        spi.tcie <= I_mem_request.data(3);
                        spi.prescaler <= I_mem_request.data(10 downto 8);
                        spi.size <= I_mem_request.data(5 downto 4);
                        -- Set clock polarity
                        spi.sck <= I_mem_request.data(2);
                    elsif I_mem_request.addr(3 downto 2) = "01" then
                        -- A write to the status register
                        spi.tc <= I_mem_request.data(3);
                    elsif I_mem_request.addr(3 downto 2) = "10" then
                        -- A write to the data register triggers a transmission
                        -- Signal start
                        spi.start <= '1';
                        -- Load transmit buffer with 8/16/24/32 data bits
                        spi.txbuffer <= (others => '0');
                        spi.data <= (others => '0');
                        -- Load the desired bits to transfer
                        case spi.size is
                            when "00" =>   spi.txbuffer(31 downto 24) <= I_mem_request.data(7 downto 0);
                                           spi.shiftcounter <= 7;
                            when "01" =>   spi.txbuffer(31 downto 16) <= I_mem_request.data(15 downto 0);
                                           spi.shiftcounter <= 15;
                            when "10" =>   spi.txbuffer(31 downto 8) <= I_mem_request.data(23 downto 0);
                                           spi.shiftcounter <= 23;
                            when "11" =>   spi.txbuffer <= I_mem_request.data;
                                           spi.shiftcounter <= 31;
                            when others => spi.txbuffer <= (others => '-');
                                           spi.shiftcounter <= 0;
                        end case;
                        -- Signal that we are sending
                        spi.tc <= '0'; 
                    end if;
                else
                    if I_mem_request.addr(3 downto 2) = "00" then
                        -- Read from control register
                        O_mem_response.data(1) <= spi.cpha;
                        O_mem_response.data(2) <= spi.cpol;
                        O_mem_response.data(3) <= spi.tcie;
                        O_mem_response.data(10 downto 8) <= spi.prescaler;
                        O_mem_response.data(5 downto 4) <= spi.size;
                    elsif I_mem_request.addr(3 downto 2) = "01" then
                        -- Read from status register
                        O_mem_response.data(3) <= spi.tc;
                    elsif I_mem_request.addr(3 downto 2) = "10" then
                        -- Read from data register
                        O_mem_response.data <= spi.data;
                        -- Clear Transmit Complete flag
                        spi.tc <= '0';
                    end if;
                end if;
                O_mem_response.ready <= '1';
            end if;

            -- Calculate prescaler, 2 to 256 in powers of 2
            case spi.prescaler is
                when "000" =>  spiprescaler_v := 0;
                when "001" =>  spiprescaler_v := 1;
                when "010" =>  spiprescaler_v := 3;
                when "011" =>  spiprescaler_v := 7;
                when "100" =>  spiprescaler_v := 15;
                when "101" =>  spiprescaler_v := 31;
                when "110" =>  spiprescaler_v := 63;
                when "111" =>  spiprescaler_v := 127;
                when others => spiprescaler_v  := 127;
            end case;

            -- Transmit/receive
            case spi.state is
                when idle =>
                    -- Clear receive buffer
                    spi.rxbuffer <= (others => '0');
                    -- Load prescaler value
                    spi.bittimer <= spiprescaler_v;
                    -- If start is active (data written)
                    if spi.start = '1' then
                        spi.state <= first;
                        spi.sck <= spi.cpol;
                        if spi.cpha = '0' then
                            spi.mosi <= spi.txbuffer(31);
                        else
                            -- CPHA = 1, write out data
                            spi.txbuffer <= spi.txbuffer(30 downto 0) & '0';
                            spi.mosi <= spi.txbuffer(31);
                            spi.sck <= not spi.cpol;
                            spi.state <= second;
                        end if;
                    else
                        spi.mosi <= spimosidefault;
                    end if;
                when first =>
                    if spi.bittimer > 0 then
                        spi.bittimer <= spi.bittimer - 1;
                    else
                        spi.bittimer <= spiprescaler_v;
                        spi.state <= second;
                        spi.sck <= not spi.cpol;
                        if spi.cpha = '0' then
                            -- CPHA = 0, clock in data from slave
                            spi.rxbuffer <= spi.rxbuffer(30 downto 0) & I_miso;
                        else
                            -- CPHA = 1, write out data
                            spi.txbuffer <= spi.txbuffer(30 downto 0) & '0';
                            spi.mosi <= spi.txbuffer(31);
                        end if;
                    end if;
                when second =>
                    if spi.bittimer > 0 then
                        spi.bittimer <= spi.bittimer - 1;
                    else
                        spi.bittimer <= spiprescaler_v;
                        spi.sck <= spi.cpol;
                        if spi.cpha = '0' then
                            -- If CPHA is 0, clock out data
                            spi.txbuffer <= spi.txbuffer(30 downto 0) & '0';
                            -- Must be spibuffer(30) because data is not yet shifted
                            spi.mosi <= spi.txbuffer(30);
                        else
                            -- If CPHA = 1, read in data from slave
                            spi.rxbuffer <= spi.rxbuffer(30 downto 0) & I_miso;
                        end if;
                        -- Are still bits left to transmit?
                        if spi.shiftcounter > 0 then
                            spi.shiftcounter <= spi.shiftcounter - 1;
                            spi.state <= first;
                        else
                            -- All bits transferred
                            if spi.cpol = '1' then
                                -- CPHA = 1, half SPI clock leadout
                                spi.state <= leadout;
                            else
                                -- CPHA = 0, no leadout, goto idle
                                spi.sck <= spi.cpol;
                                spi.tc <= '1';
                                spi.mosi <= spimosidefault;
                                spi.state <= idle;
                                -- Copy to data register
                                spi.data <= spi.rxbuffer;
                            end if;
                        end if;
                    end if;
                when leadout =>
                    -- Hold the data half SPI clock cycle
                    if spi.bittimer > 0 then
                        spi.bittimer <= spi.bittimer - 1;
                    else
                        spi.sck <= spi.cpol;
                        spi.tc <= '1';
                        spi.mosi <= spimosidefault;
                        spi.state <= idle;
                    end if;
                    -- Copy to data register
                    spi.data <= spi.rxbuffer;
            when others => null;
            end case;
        end if; -- rising_edge
    end process;
    
    O_sck <= spi.sck;
    O_mosi <= spi.mosi;
    O_irq <= spi.tcie and spi.tc;

end architecture rtl;