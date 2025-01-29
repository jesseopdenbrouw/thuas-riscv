-- #################################################################################################
-- # timerb.vhd - Complex 16-bit timer with PWM/OC/IC                                              #
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

entity timerb is
    port (I_clk : in std_logic;
          I_areset : in std_logic;
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
end entity timerb;

architecture rtl of timerb is

type timerb_type is record
    en : std_logic;                       -- Timer enable
    os : std_logic;                       -- One-shot
    tcie : std_logic;                     -- T Compare Match Interrupt Enable
    acie : std_logic;                     -- A Compare Match Interrupt Enable
    bcie : std_logic;                     -- B Compare Match Interrupt Enable
    ccie : std_logic;                     -- C Compare Match Interrupt Enable
    pret : std_logic;                     -- Preload T Register
    prea : std_logic;                     -- Preload A Register
    preb : std_logic;                     -- Preload B Register
    prec : std_logic;                     -- Preload C Register
    modet : std_logic_vector(2 downto 0); -- T Mode
    phat : std_logic;                     -- T Start Phase
    modea : std_logic_vector(2 downto 0); -- A Mode
    phaa : std_logic;                     -- A Start Phase
    modeb : std_logic_vector(2 downto 0); -- B Mode
    phab : std_logic;                     -- B Start Phase
    modec : std_logic_vector(2 downto 0); -- C Mode
    phac : std_logic;                     -- C Start Phase
    tc : std_logic;                       -- T Compare Match
    ac : std_logic;                       -- A Compare Match
    bc : std_logic;                       -- B Compare Match
    cc : std_logic;                       -- C Compare Match
    cntr : std_logic_vector(15 downto 0); -- Counter Register
    cmpt : std_logic_vector(15 downto 0); -- Compare T regeister
    prsc : std_logic_vector(15 downto 0); -- Prescale Register
    cmpa : std_logic_vector(15 downto 0); -- Compare A Register
    cmpb : std_logic_vector(15 downto 0); -- Compare B Register
    cmpc : std_logic_vector(15 downto 0); -- Compare C Register
    -- internal prescaler
    prescaler : std_logic_vector(15 downto 0);
    -- shadow registers
    cmptshadow : std_logic_vector(15 downto 0);
    cmpashadow : std_logic_vector(15 downto 0);
    cmpbshadow : std_logic_vector(15 downto 0);
    cmpcshadow : std_logic_vector(15 downto 0);
    prscshadow : std_logic_vector(15 downto 0);
    oct : std_logic;
    oca : std_logic;
    ocb : std_logic;
    occ : std_logic;
    ocaen : std_logic;
    ocben : std_logic;
    occen : std_logic;
    icasync : std_logic_vector(2 downto 0);
    icbsync : std_logic_vector(2 downto 0);
    iccsync : std_logic_vector(2 downto 0);
end record;

signal timerb : timerb_type;
signal isword : boolean;
-- For strobing
signal cs_sync : std_logic;

begin

    O_mem_response.load_misaligned_error <= '1' when I_mem_request.cs = '1' and I_mem_request.wren = '0' and I_mem_request.size /= memsize_word else '0';
    O_mem_response.store_misaligned_error <= '1' when I_mem_request.cs = '1' and I_mem_request.wren = '1' and I_mem_request.size /= memsize_word else '0';
    isword <= I_mem_request.size = memsize_word;

    process (I_clk, I_areset) is
    begin
        if I_areset = '1' then
            -- The I/O registers
            timerb.en <= '0';
            timerb.os <= '0';
            timerb.tcie <= '0';
            timerb.acie <= '0';
            timerb.bcie <= '0';
            timerb.ccie <= '0';
            timerb.pret <= '0';
            timerb.prea <= '0';
            timerb.preb <= '0';
            timerb.prec <= '0';
            timerb.modet <= (others => '0');
            timerb.phat <= '0';
            timerb.modea <= (others => '0');
            timerb.phaa <= '0';
            timerb.modeb <= (others => '0');
            timerb.phab <= '0';
            timerb.modec <= (others => '0');
            timerb.phac <= '0';
            timerb.tc <= '0';
            timerb.ac <= '0';
            timerb.bc <= '0';
            timerb.cc <= '0';
            timerb.cntr <= (others => '0');
            timerb.cmpt <= (others => '0');
            timerb.prsc <= (others => '0');
            timerb.cmpa <= (others => '0');
            timerb.cmpb <= (others => '0');
            timerb.cmpc <= (others => '0');
            -- The internal prescaler
            timerb.prescaler <= (others => '0');
            -- The shadow registers
            timerb.prscshadow <= (others => '0');
            timerb.cmptshadow <= (others => '0');
            timerb.cmpashadow <= (others => '0');
            timerb.cmpbshadow <= (others => '0');
            timerb.cmpcshadow <= (others => '0');
            -- The OC outputs
            timerb.oct <= '0';
            timerb.oca <= '0';
            timerb.ocb <= '0';
            timerb.occ <= '0';
            -- The IC synchronizers
            timerb.icasync <= (others => '0');
            timerb.icbsync <= (others => '0');
            timerb.iccsync <= (others => '0');
            -- Reset resonse
            O_mem_response.data <= all_zeros_c;
            O_mem_response.ready <= '0';
            cs_sync <= '0';
        elsif rising_edge(I_clk) then
            O_mem_response.data <= all_zeros_c;
            O_mem_response.ready <= '0';
            cs_sync <= I_mem_request.cs;
            if I_mem_request.cs = '1' and cs_sync = '0' and isword then
                if I_mem_request.wren = '1' then
                    if I_mem_request.addr(4 downto 2) = "000" then
                        -- Write Timer Control Register
                        -- Check if one or more FOC bits are set
                        -- If so, the data is NOT copied to the CTRL register
                        -- and the MODE bits indicate the FOC action
                        if I_mem_request.data(31 downto 28) /= "0000" then
                            -- FOCT
                            if I_mem_request.data(28) = '1' then
                                case I_mem_request.data(14 downto 12) is
                                    when "001" => timerb.oct <= not timerb.oct;
                                    when "010" => timerb.oct <= '1';
                                    when "011" => timerb.oct <= '0';
                                    when others => null;
                                end case;
                            end if;
                            -- FOCA
                            if I_mem_request.data(29) = '1' then
                                case I_mem_request.data(18 downto 16) is
                                    when "001" => timerb.oca <= not timerb.oca;
                                    when "010" => timerb.oca <= '1';
                                    when "011" => timerb.oca <= '0';
                                    when others => null;
                                end case;
                            end if;
                            -- FOCB
                            if I_mem_request.data(30) = '1' then
                                case I_mem_request.data(22 downto 20) is
                                    when "001" => timerb.ocb <= not timerb.ocb;
                                    when "010" => timerb.ocb <= '1';
                                    when "011" => timerb.ocb <= '0';
                                    when others => null;
                                end case;
                            end if;
                            -- FOCC
                            if I_mem_request.data(31) = '1' then
                                case I_mem_request.data(26 downto 24) is
                                    when "001" => timerb.occ <= not timerb.occ;
                                    when "010" => timerb.occ <= '1';
                                    when "011" => timerb.occ <= '0';
                                    when others => null;
                                end case;
                            end if;
                        else
                            -- No FOC bits set, so ...
                            -- Copy to CTRL register
                            timerb.en <= I_mem_request.data(0);
                            timerb.os <= I_mem_request.data(3);
                            timerb.tcie <= I_mem_request.data(4);
                            timerb.acie <= I_mem_request.data(5);
                            timerb.bcie <= I_mem_request.data(6);
                            timerb.ccie <= I_mem_request.data(7);
                            timerb.pret <= I_mem_request.data(8);
                            timerb.prea <= I_mem_request.data(9);
                            timerb.preb <= I_mem_request.data(10);
                            timerb.prec <= I_mem_request.data(11);
                            timerb.modet <= I_mem_request.data(14 downto 12);
                            timerb.phat <= I_mem_request.data(15);
                            timerb.modea <= I_mem_request.data(18 downto 16);
                            timerb.phaa <= I_mem_request.data(19);
                            timerb.modeb <= I_mem_request.data(22 downto 20);
                            timerb.phab <= I_mem_request.data(23);
                            timerb.modec <= I_mem_request.data(26 downto 24);
                            timerb.phac <= I_mem_request.data(27);
                            -- Set the signal phase
                            timerb.oct <= I_mem_request.data(15);
                            timerb.oca <= I_mem_request.data(19);
                            timerb.ocb <= I_mem_request.data(23);
                            timerb.occ <= I_mem_request.data(27);
                            -- If the CMPA register is all zero and we start, then
                            -- set the output compare immediate, but don't flag it
                            if timerb.cmpa = x"0000" and I_mem_request.data(0) = '1' then
                                if I_mem_request.data(18 downto 16) = "001" then
                                    timerb.oca <= not I_mem_request.data(19);
                                elsif I_mem_request.data(18 downto 16) = "010" and I_mem_request.data(0) = '1' then
                                    timerb.oca <= not I_mem_request.data(19);
                                elsif I_mem_request.data(18 downto 16) = "011" and I_mem_request.data(0) = '1' then
                                    timerb.oca <= I_mem_request.data(19);
                                end if;
                            end if;
                            -- If the CMPB register is all zero and we start, then
                            -- set the output compare immediate, but don't flag it
                            if timerb.cmpb = x"0000" and I_mem_request.data(0) = '1' then
                                if I_mem_request.data(22 downto 20) = "001" then
                                    timerb.ocb <= not I_mem_request.data(23);
                                elsif I_mem_request.data(22 downto 20) = "010" and I_mem_request.data(0) = '1' then
                                    timerb.ocb <= not I_mem_request.data(23);
                                elsif I_mem_request.data(22 downto 20) = "011" and I_mem_request.data(0) = '1' then
                                    timerb.ocb <= I_mem_request.data(23);
                                end if;
                            end if;
                            -- If the CMPC register is all zero and we start, then
                            -- set the output compare immediate, but don't flag it
                            if timerb.cmpc = x"0000" and I_mem_request.data(0) = '1' then
                                if I_mem_request.data(26 downto 24) = "001" then
                                    timerb.occ <= not I_mem_request.data(27);
                                elsif I_mem_request.data(26 downto 24) = "010" and I_mem_request.data(0) = '1' then
                                    timerb.occ <= not I_mem_request.data(27);
                                elsif I_mem_request.data(26 downto 24) = "011" and I_mem_request.data(0) = '1' then
                                    timerb.occ <= I_mem_request.data(27);
                                end if;
                            end if;
                        end if; -- end yes/no FOCx
                    end if; -- end ctrl
                    -- Write Timer Status Register
                    if I_mem_request.addr(4 downto 2) = "001" then
                        timerb.tc <= I_mem_request.data(4);
                        timerb.ac <= I_mem_request.data(5);
                        timerb.bc <= I_mem_request.data(6);
                        timerb.cc <= I_mem_request.data(7);
                    end if;
                    -- Write Timer Counter Register
                    if I_mem_request.addr(4 downto 2) = "010" then
                        timerb.cntr <= I_mem_request.data(15 downto 0);
                    end if;
                    -- Write Timer Compare T Register
                    if I_mem_request.addr(4 downto 2) = "011" then
                        timerb.cmpt <= I_mem_request.data(15 downto 0);
                        -- If the timer is stopped or preload is off, directly write the shadow register
                        if timerb.en = '0' or timerb.pret = '0' then
                            timerb.cmptshadow <= I_mem_request.data(15 downto 0);
                        end if;
                    end if;
                    -- Write Prescaler Register
                    if I_mem_request.addr(4 downto 2) = "100" then
                        timerb.prsc <= I_mem_request.data(15 downto 0);
                        -- If the timer is stopped, directly write the shadow register
                        if timerb.en = '0' then
                            timerb.prscshadow <= I_mem_request.data(15 downto 0);
                        end if;
                        -- Reset internal prescaler
                        timerb.prescaler <= (others => '0');
                    end if;
                    -- Write Timer Compare A Register
                    if I_mem_request.addr(4 downto 2) = "101" then
                        timerb.cmpa <= I_mem_request.data(15 downto 0);
                        -- If the timer is stopped or preload is off, directly write the shadow register
                        if timerb.en = '0' or timerb.prea = '0' then
                            timerb.cmpashadow <= I_mem_request.data(15 downto 0);
                        end if;
                    end if;
                    -- Write Timer Compare B Register
                    if I_mem_request.addr(4 downto 2) = "110" then
                        timerb.cmpb <= I_mem_request.data(15 downto 0);
                        -- If the timer is stopped or preload is off, directly write the shadow register
                        if timerb.en = '0' or timerb.preb = '0' then
                            timerb.cmpbshadow <= I_mem_request.data(15 downto 0);
                        end if;
                    end if;
                    -- Write Timer Compare C Register
                    if I_mem_request.addr(4 downto 2) = "111" then
                        timerb.cmpc <= I_mem_request.data(15 downto 0);
                        -- If the timer is stopped or preload is off, directly write the shadow register
                        if timerb.en = '0' or timerb.prec = '0' then
                            timerb.cmpcshadow <= I_mem_request.data(15 downto 0);
                        end if;
                    end if;
                else
                    -- Read control register
                    if I_mem_request.addr(4 downto 2) = "000" then
                        O_mem_response.data <= "0000" & timerb.phac & timerb.modec &
                                          timerb.phab & timerb.modeb & timerb.phaa & timerb.modea & timerb.phat & timerb.modet &
                                          timerb.prec & timerb.preb & timerb.prea & timerb.pret & timerb.ccie & timerb.bcie &
                                          timerb.acie & timerb.tcie & timerb.os & "00" & timerb.en;
                    end if;
                    -- Read status register
                    if I_mem_request.addr(4 downto 2) = "001" then
                        O_mem_response.data(7 downto 4) <= timerb.cc & timerb.bc & timerb.ac & timerb.tc;
                    end if;
                    -- Read counter register
                    if I_mem_request.addr(4 downto 2) = "010" then
                        O_mem_response.data(15 downto 0) <= timerb.cntr;
                    end if;
                    -- Read CMPT register
                    if I_mem_request.addr(4 downto 2) = "011" then
                        O_mem_response.data(15 downto 0) <= timerb.cmpt;
                    end if;
                    -- Read PRSC register
                    if I_mem_request.addr(4 downto 2) = "100" then
                        O_mem_response.data(15 downto 0) <= timerb.prsc;
                    end if;
                 -- Read CMPA register
                    if I_mem_request.addr(4 downto 2) = "101" then
                        O_mem_response.data(15 downto 0) <= timerb.cmpa;
                    end if;
                    -- Read CMPB register
                    if I_mem_request.addr(4 downto 2) = "110" then
                        O_mem_response.data(15 downto 0) <= timerb.cmpb;
                    end if;
                    -- Read CMPC register
                    if I_mem_request.addr(4 downto 2) = "111" then
                        O_mem_response.data(15 downto 0) <= timerb.cmpc;
                    end if;
                end if; -- end wren = 1
                O_mem_response.ready <= '1';
            end if; -- end cs = 1
            
            -- If timer is enabled....
            if timerb.en= '1' then
                -- If internal prescaler at end...
                if timerb.prescaler >= timerb.prscshadow then
                    -- Wrap internal prescaler
                    timerb.prescaler <= (others => '0');
                    -- If we hit the Compare Register T...
                    if timerb.cntr >= timerb.cmptshadow then
                        -- Clear Counter Register
                        timerb.cntr <= (others => '0');
                        -- Signal hit
                        timerb.tc <= '1';
                        -- Toggle OCT, or not
                        case timerb.modet is
                            when "000" => timerb.oct <= '0'; -- off
                            when "001" => timerb.oct <= not timerb.oct; -- toggle
                            when "010" => timerb.oct <= not timerb.phat; -- invert PHAT
                            when "011" => timerb.oct <= timerb.phat; -- write PHAT
                            -- Others not allowed, as T does not have PWM mode
                            when others => timerb.oct <= '0';
                        end case;
                        -- If we have a one-shot, disable timer
                        if timerb.os = '1' then
                            timerb.en <= '0';
                            timerb.prescaler <= (others => '0');
                        end if;
                    else
                        -- If we are at the last step - 1 ...
                        if timerb.cntr = std_logic_vector(unsigned(timerb.cmptshadow)-1) then
                            -- Load PRSC shadow register
                            timerb.prscshadow <= timerb.prsc;
                            -- Load CMPT shadow register
                            timerb.cmptshadow <= timerb.cmpt;
                            -- Load CMPA shadow register
                            timerb.cmpashadow <= timerb.cmpa;
                            -- Load CMPB shadow register
                            timerb.cmpbshadow <= timerb.cmpb;
                            -- Load CMPC shadow register
                            timerb.cmpcshadow <= timerb.cmpc;
                        end if;
                        -- else, increment the Counter Register
                        timerb.cntr <= std_logic_vector(unsigned(timerb.cntr) + 1);
                    end if;
                else
                    timerb.prescaler <= std_logic_vector(unsigned(timerb.prescaler) + 1);
                end if;

                -- If we are at the end of prescale counting
                if timerb.prescaler >= timerb.prscshadow then
                    -- Sync the IC inputs
                    timerb.icasync <= timerb.icasync(1 downto 0) & IO_timericoca;
                    timerb.icbsync <= timerb.icbsync(1 downto 0) & IO_timericocb;
                    timerb.iccsync <= timerb.iccsync(1 downto 0) & IO_timericocc;
                
                    -- Check CMPA for mode
                    case timerb.modea is
                        -- 000 = do nothing
                        when "000" => timerb.oca <= '0';
                        -- 001 = toggle on compare match
                        when "001" =>
                            if timerb.cmpashadow = x"0000" and timerb.cntr = timerb.cmptshadow then
                                timerb.oca <= not timerb.oca;
                                timerb.ac <= '1';
                            elsif timerb.cntr = std_logic_vector(unsigned(timerb.cmpashadow)-1) then
                                timerb.oca <= not timerb.oca;
                                timerb.ac <= '1';
                            end if;
                        -- 010 = activate on compare match, invert PHAA
                        when "010" =>
                            if timerb.cmpashadow = x"0000" and timerb.cntr = timerb.cmptshadow then
                                timerb.oca <= not timerb.phaa;
                                timerb.ac <= '1';
                            elsif timerb.cntr = std_logic_vector(unsigned(timerb.cmpashadow)-1) then
                                timerb.oca <= not timerb.phaa;
                                timerb.ac <= '1';
                            end if;
                        -- 011 = deactivate on compare match, write PHAA
                        when "011" =>
                            if timerb.cmpashadow = x"0000" and timerb.cntr = timerb.cmptshadow then
                                timerb.oca <= timerb.phaa;
                                timerb.ac <= '1';
                            elsif timerb.cntr = std_logic_vector(unsigned(timerb.cmpashadow)-1) then
                                timerb.oca <= timerb.phaa;
                                timerb.ac <= '1';
                            end if;
                        -- 100 = edge aligned PWM
                        when "100" =>
                            if timerb.cmpashadow = x"0000" then
                                timerb.oca <= timerb.phaa;
                            elsif timerb.cntr < std_logic_vector(unsigned(timerb.cmpashadow)-1) or (timerb.cntr = timerb.cmptshadow and timerb.os = '0') then
                                timerb.oca <= not timerb.phaa;
                            else
                                timerb.oca <= timerb.phaa;
                            end if;
                            if timerb.cntr = std_logic_vector(unsigned(timerb.cmpashadow)-1) then
                                timerb.ac <= '1';
                            end if;
                        -- 110 - positive edge detected
                        when "110" =>
                            if timerb.icasync(2 downto 1) = "01" then
                                -- Copy CNTR to CMPA register and raise interrupt
                                timerb.cmpa <= timerb.cntr;
                                timerb.ac <= '1';
                            end if;
                        -- 111 - negative edge detected
                        when "111" =>
                            if timerb.icasync(2 downto 1) = "10" then
                                -- Copy CNTR to CMPA register and raise interrupt
                                timerb.cmpa <= timerb.cntr;
                                timerb.ac <= '1';
                            end if;
                        -- Others not allowed
                        when others => timerb.oca <= '0';
                    end case;
                    -- Check CMPB for mode
                    case timerb.modeb is
                        -- 000 = do nothing
                        when "000" => timerb.ocb <= '0';
                        -- 001 = toggle on compare match
                        when "001" =>
                            if timerb.cmpbshadow = x"0000" and timerb.cntr = timerb.cmptshadow then
                                timerb.ocb <= not timerb.ocb;
                                timerb.bc <= '1';
                            elsif timerb.cntr = std_logic_vector(unsigned(timerb.cmpbshadow)-1) then
                                timerb.ocb <= not timerb.ocb;
                                timerb.bc <= '1';
                            end if;
                        -- 010 = activate on compare match, invert PHAB
                        when "010" =>
                            if timerb.cmpbshadow = x"0000" and timerb.cntr = timerb.cmptshadow then
                                timerb.ocb <= not timerb.phab;
                                timerb.bc <= '1';
                            elsif timerb.cntr = std_logic_vector(unsigned(timerb.cmpbshadow)-1) then
                                timerb.ocb <= not timerb.phab;
                                timerb.bc <= '1';
                            end if;
                        -- 011 = deactivate on compare match, write PHAB
                        when "011" =>
                            if timerb.cmpbshadow = x"0000" and timerb.cntr = timerb.cmptshadow then
                                timerb.ocb <= timerb.phab;
                                timerb.bc <= '1';
                            elsif timerb.cntr = std_logic_vector(unsigned(timerb.cmpbshadow)-1) then
                                timerb.ocb <= timerb.phab;
                                timerb.bc <= '1';
                            end if;
                        -- 100 = edge aligned PWM
                        when "100" =>
                            if timerb.cmpbshadow = x"0000" then
                                timerb.ocb <= timerb.phab;
                            elsif timerb.cntr < std_logic_vector(unsigned(timerb.cmpbshadow)-1) or (timerb.cntr = timerb.cmptshadow and timerb.os = '0') then
                                timerb.ocb <= not timerb.phab;
                            else
                                timerb.ocb <= timerb.phab;
                            end if;
                            if timerb.cntr = std_logic_vector(unsigned(timerb.cmpbshadow)-1) then
                                timerb.bc <= '1';
                            end if;
                        -- 110 - positive edge detected
                        when "110" =>
                            if timerb.icbsync(2 downto 1) = "01" then
                                -- Copy CNTR to CMPB register and raise interrupt
                                timerb.cmpb <= timerb.cntr;
                                timerb.bc <= '1';
                            end if;
                        -- 111 - negative edge detected
                        when "111" =>
                            if timerb.icbsync(2 downto 1) = "10" then
                                -- Copy CNTR to CMPB register and raise interrupt
                                timerb.cmpb <= timerb.cntr;
                                timerb.bc <= '1';
                            end if;
                        when others => timerb.ocb <= '0';
                    end case;
                    -- Check CMPC for mode
                    case timerb.modec is
                        -- 000 = do nothing
                        when "000" => timerb.occ <= '0';
                        -- 001 = toggle on compare match
                        when "001" =>
                            if timerb.cmpcshadow = x"0000" and timerb.cntr = timerb.cmptshadow then
                                timerb.occ <= not timerb.occ;
                                timerb.cc <= '1';
                            elsif timerb.cntr = std_logic_vector(unsigned(timerb.cmpcshadow)-1) then
                                timerb.occ <= not timerb.occ;
                                timerb.cc <= '1';
                            end if;
                        -- 010 = activate on compare match, invert PHAC
                        when "010" =>
                            if timerb.cmpcshadow = x"0000" and timerb.cntr = timerb.cmptshadow then
                                timerb.occ <= not timerb.phac;
                                timerb.cc <= '1';
                            elsif timerb.cntr = std_logic_vector(unsigned(timerb.cmpcshadow)-1) then
                                timerb.occ <= not timerb.phac;
                                timerb.cc <= '1';
                            end if;
                        -- 011 = deactivate on compare match, write PHAC
                        when "011" =>
                            if timerb.cmpcshadow = x"0000" and timerb.cntr = timerb.cmptshadow then
                                timerb.occ <= timerb.phac;
                                timerb.cc <= '1';
                            elsif timerb.cntr = std_logic_vector(unsigned(timerb.cmpcshadow)-1) then
                                timerb.occ <= timerb.phac;
                                timerb.cc <= '1';
                            end if;
                        -- 100 = edge aligned PWM
                        when "100" =>
                            if timerb.cmpcshadow = x"0000" then
                                timerb.occ <= timerb.phac;
                            elsif timerb.cntr < std_logic_vector(unsigned(timerb.cmpcshadow)-1) or (timerb.cntr = timerb.cmptshadow and timerb.os = '0') then
                                timerb.occ <= not timerb.phac;
                            else
                                timerb.occ <= timerb.phac;
                            end if;
                            if timerb.cntr = std_logic_vector(unsigned(timerb.cmpcshadow)-1) then
                                timerb.cc <= '1';
                            end if;
                        -- 110 - positive edge detected
                        when "110" =>
                            if timerb.iccsync(2 downto 1) = "01" then
                                -- Copy CNTR to CMPC register and raise interrupt
                                timerb.cmpc <= timerb.cntr;
                                timerb.cc <= '1';
                            end if;
                        -- 111 - negative edge detected
                        when "111" =>
                            if timerb.iccsync(2 downto 1) = "10" then
                                -- Copy CNTR to CMPC register and raise interrupt
                                timerb.cmpc <= timerb.cntr;
                                timerb.cc <= '1';
                            end if;
                        when others => timerb.occ <= '0';
                    end case;
                end if; -- end prescaler match
            end if; -- timer enabled
        end if;
    end process;

    -- Generate Output Enabled
    timerb.ocaen <= '1' when timerb.modea = "001" or
                             timerb.modea = "010" or
                             timerb.modea = "011" or
                             timerb.modea = "100"
                           else '0';
    timerb.ocben <= '1' when timerb.modeb = "001" or
                             timerb.modeb = "010" or
                             timerb.modeb = "011" or
                             timerb.modeb = "100"
                           else '0';
    timerb.occen <= '1' when timerb.modec = "001" or
                             timerb.modec = "010" or
                             timerb.modec = "011" or
                             timerb.modec = "100"
                           else '0';
    -- Output the Output Compare match
    O_timeroct <= timerb.oct;
    IO_timericoca <= timerb.oca when timerb.ocaen = '1' else 'Z';
    IO_timericocb <= timerb.ocb when timerb.ocben = '1' else 'Z';
    IO_timericocc <= timerb.occ when timerb.occen = '1' else 'Z';
    
    O_irq <= (timerb.tcie and timerb.tc) or (timerb.acie and timerb.ac) or (timerb.bcie and timerb.bc) or (timerb.ccie and timerb.cc);
    
end architecture rtl;