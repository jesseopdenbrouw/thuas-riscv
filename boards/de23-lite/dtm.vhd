-- ================================================================================ --
-- NEORV32 OCD - RISC-V-Compatible Debug Transport Module (DTM)                     --
-- -------------------------------------------------------------------------------- --
-- Compatible to RISC-V debug spec. versions 0.13 and 1.0.                          --
-- -------------------------------------------------------------------------------- --
-- The NEORV32 RISC-V Processor - https://github.com/stnolting/neorv32              --
-- Copyright (c) NEORV32 contributors.                                              --
-- Copyright (c) 2020 - 2026 Stephan Nolting. All rights reserved.                  --
-- Licensed under the BSD-3-Clause license, see LICENSE for details.                --
-- SPDX-License-Identifier: BSD-3-Clause                                            --
-- ================================================================================ --

-- This is an implementation of S.T. Nolting's DTM module.
-- See https://github.com/stnolting/neorv32/blob/main/rtl/core/neorv32_debug_dtm.vhd
-- The structure of the hardware is the same, but the naming of some signals is
-- different.

library ieee;
use ieee.std_logic_1164.all;

library work;
use work.processor_common.all;

entity dtm is
    generic (
        IDCODE_VERSION : std_logic_vector(3 downto 0);  -- version
        IDCODE_PARTID  : std_logic_vector(15 downto 0); -- part number
        IDCODE_MANID   : std_logic_vector(10 downto 0)  -- manufacturer id
       );
    port (
        -- global control --
        I_clk     : in std_logic; -- global clock line
        I_areset  : in std_logic; -- global asynchronous reset line
        I_sreset  : in std_logic; -- global synchronous reset
        -- JTAG connection (TAP access) --
        I_tck : in  std_logic; -- serial clock
        I_tdi : in  std_logic; -- serial data input
        O_tdo : out std_logic; -- serial data output
        I_tms : in  std_logic; -- mode select
        -- debug module interface (DMI) --
        O_dmi_request   : out dmi_request_type;
        I_dmi_response  : in  dmi_response_type
       );
end dtm;

architecture rtl of dtm is

    -- TAP data registers --
    constant addr_idcode_c : std_logic_vector(4 downto 0) := "00001";
    constant addr_dtmcs_c  : std_logic_vector(4 downto 0) := "10000";
    constant addr_dmi_c    : std_logic_vector(4 downto 0) := "10001";
    constant addr_bypass_c : std_logic_vector(4 downto 0) := "11111";
    --
    constant size_idcode_c : natural := 32;
    constant size_dtmcs_c  : natural := 32;
    constant size_dmi_c    : natural := 7+32+2; -- 7-bit address + 32-bit data + 2-bit operation/status
    constant size_bypass_c : natural := 1;

    -- JTAG signal synchronizer --
    signal tck_ff : std_logic_vector(2 downto 0);
    signal tdi_ff, tms_ff : std_logic_vector(1 downto 0);
    signal tck_rise, tck_fall, tdi, tms : std_logic;

    -- TAP controller --
    type state_t is (LOGIC_RESET, DR_SCAN, DR_CAPTURE, DR_SHIFT, DR_EXIT1, DR_PAUSE, DR_EXIT2, DR_UPDATE,
                      RUN_IDLE, IR_SCAN, IR_CAPTURE, IR_SHIFT, IR_EXIT1, IR_PAUSE, IR_EXIT2, IR_UPDATE);
    signal state, state2 : state_t;

    -- TAP registers --
    signal ireg : std_logic_vector(4 downto 0);
    signal dreg : std_logic_vector(size_dmi_c-1 downto 0); -- max size (= dmi size)

    -- misc --
    signal update, dmihardreset, dmireset : std_logic;

    -- debug module interface controller --
    signal dmi : dmi_request_type;
    signal busy, err : std_logic;

begin

    -- JTAG Input Synchronizer ----------------------------------------------------------------
    -- -------------------------------------------------------------------------------------------
    tap_synchronizer: process (I_clk, I_areset) is
    begin
        if I_areset = '1' then
            tck_ff <= (others => '0');
            tdi_ff <= (others => '0');
            tms_ff <= (others => '0');
        elsif rising_edge(I_clk) then
            if I_sreset = '1' then
                tck_ff <= (others => '0');
                tdi_ff <= (others => '0');
                tms_ff <= (others => '0');
            else
                tck_ff <= tck_ff(1 downto 0) & I_tck;
                tdi_ff <= tdi_ff(0) & I_tdi;
                tms_ff <= tms_ff(0) & I_tms;
            end if;
        end if;
    end process tap_synchronizer;

    -- JTAG clock edges --
    tck_rise <= '1' when (tck_ff(2 downto 1) = "01") else '0';
    tck_fall <= '1' when (tck_ff(2 downto 1) = "10") else '0';

    -- JTAG inputs --
    tms <= tms_ff(1);
    tdi <= tdi_ff(1);


    -- JTAG Tap Control FSM -------------------------------------------------------------------
    -- -------------------------------------------------------------------------------------------
    tap_control: process (I_clk, I_areset) is
    begin
        if I_areset = '1' then
            state2 <= LOGIC_RESET;
            state  <= LOGIC_RESET;
        elsif rising_edge(I_clk) then
            if I_sreset = '1' then
                state2 <= LOGIC_RESET;
                state  <= LOGIC_RESET;
            else
                state2 <= state;
                if tck_rise = '1' then -- clock pulse (evaluate TMS on the rising edge of TCK)
                    case state is -- JTAG state machine
                        when LOGIC_RESET => if (tms = '0') then state <= RUN_IDLE;   else state <= LOGIC_RESET; end if;
                        when RUN_IDLE    => if (tms = '0') then state <= RUN_IDLE;   else state <= DR_SCAN;     end if;
                        when DR_SCAN     => if (tms = '0') then state <= DR_CAPTURE; else state <= IR_SCAN;     end if;
                        when DR_CAPTURE  => if (tms = '0') then state <= DR_SHIFT;   else state <= DR_EXIT1;    end if;
                        when DR_SHIFT    => if (tms = '0') then state <= DR_SHIFT;   else state <= DR_EXIT1;    end if;
                        when DR_EXIT1    => if (tms = '0') then state <= DR_PAUSE;   else state <= DR_UPDATE;   end if;
                        when DR_PAUSE    => if (tms = '0') then state <= DR_PAUSE;   else state <= DR_EXIT2;    end if;
                        when DR_EXIT2    => if (tms = '0') then state <= DR_SHIFT;   else state <= DR_UPDATE;   end if;
                        when DR_UPDATE   => if (tms = '0') then state <= RUN_IDLE;   else state <= DR_SCAN;     end if;
                        when IR_SCAN     => if (tms = '0') then state <= IR_CAPTURE; else state <= LOGIC_RESET; end if;
                        when IR_CAPTURE  => if (tms = '0') then state <= IR_SHIFT;   else state <= IR_EXIT1;    end if;
                        when IR_SHIFT    => if (tms = '0') then state <= IR_SHIFT;   else state <= IR_EXIT1;    end if;
                        when IR_EXIT1    => if (tms = '0') then state <= IR_PAUSE;   else state <= IR_UPDATE;   end if;
                        when IR_PAUSE    => if (tms = '0') then state <= IR_PAUSE;   else state <= IR_EXIT2;    end if;
                        when IR_EXIT2    => if (tms = '0') then state <= IR_SHIFT;   else state <= IR_UPDATE;   end if;
                        when IR_UPDATE   => if (tms = '0') then state <= RUN_IDLE;   else state <= DR_SCAN;     end if;
                        when others      => state <= LOGIC_RESET;
                    end case;
                end if;
            end if; -- sreset
        end if; -- posedge
    end process tap_control;

    -- DR_UPDATE edge detector --
    update <= '1' when (state = DR_UPDATE) and (state2 /= DR_UPDATE) else '0';


    -- Tap Register Access --------------------------------------------------------------------
    -- -------------------------------------------------------------------------------------------
    reg_access: process (I_clk, I_areset) is
    begin
        if I_areset = '1' then
            ireg   <= (others => '0');
            dreg   <= (others => '0');
            O_tdo  <= '0';
        elsif rising_edge(I_clk) then
            if I_sreset = '1' then
                ireg   <= (others => '0');
                dreg   <= (others => '0');
                O_tdo  <= '0';
            else
                -- instruction register input --
                if (state = LOGIC_RESET) or (state = IR_CAPTURE) then -- capture phase
                    ireg <= addr_idcode_c;
                elsif (state = IR_SHIFT) and (tck_rise = '1') then -- access phase; [JTAG-SYNC] evaluate TDI on rising edge of TCK
                    ireg <= tdi & ireg(ireg'left downto 1);
                end if;
                -- data register input --
                if state = DR_CAPTURE then -- capture phase
                    case ireg is -- [NOTE] make data MSB-aligned and fill with zeros
                        when addr_idcode_c => dreg <= IDCODE_VERSION & IDCODE_PARTID & IDCODE_MANID & '1' & "000000000";
                        when addr_dtmcs_c  => dreg <= x"00000071" & "000000000";
                        when addr_dmi_c    => dreg <= dmi.addr & dmi.data & err & err;
                        when others        => dreg <= (others => '0');
                    end case;
                elsif (state = DR_SHIFT) and (tck_rise = '1') then -- access phase; [JTAG-SYNC] evaluate TDI on rising edge of TCK
                    dreg <= tdi & dreg(dreg'left downto 1);
                end if;
                -- output --
                if tck_fall = '1' then -- [JTAG-SYNC] update TDO on falling edge of TCK
                    if state = IR_SHIFT then
                        O_tdo <= ireg(0);
                    elsif state = DR_SHIFT then
                        case ireg is -- data is MSB-aligned so select the logical LSB as output
                            when addr_idcode_c => O_tdo <= dreg(dreg'left-(size_idcode_c-1));
                            when addr_dtmcs_c  => O_tdo <= dreg(dreg'left-(size_dtmcs_c-1));
                            when addr_dmi_c    => O_tdo <= dreg(dreg'left-(size_dmi_c-1));
                            when others        => O_tdo <= dreg(dreg'left-(size_bypass_c-1));
                        end case;
                    end if;
                end if;
             end if; -- sreset
        end if; -- posedge
    end process reg_access;

    -- reset control; [NOTE] dreg bits are LSB-aligned --
    dmihardreset <= '1' when (update = '1') and (ireg = addr_dtmcs_c) and (dreg((dreg'left - (size_dtmcs_c-1)) + 17) = '1') else '0';
    dmireset     <= '1' when (update = '1') and (ireg = addr_dtmcs_c) and (dreg((dreg'left - (size_dtmcs_c-1)) + 16) = '1') else '0';


    -- Debug Module Interface -----------------------------------------------------------------
    -- -------------------------------------------------------------------------------------------
    dmi_controller: process (I_clk, I_areset) is
    begin
        if I_areset = '1' then
            err  <= '0';
            busy <= '0';
            dmi.data <= (others => '0');
            dmi.addr <= (others => '0');
            dmi.op <= (others => '0');
        elsif rising_edge(I_clk) then
            if I_sreset = '1' then
                err  <= '0';
                busy <= '0';
                dmi.data <= (others => '0');
                dmi.addr <= (others => '0');
                dmi.op <= (others => '0');
            else
                -- sticky error: access attempt while DMI is busy --
                if (dmireset = '1') or (dmihardreset = '1') then
                    err <= '0';
                elsif (update = '1') and (ireg = addr_dmi_c) and (busy = '1') then
                    err <= '1';
                end if;
                -- interface arbiter --
                dmi.op <= dmi_req_nop_c; -- default
                if busy = '0' then -- idle: waiting for new request
                    if (update = '1') and (ireg = addr_dmi_c) then
                        dmi.addr <= dreg(40 downto 34);
                        dmi.data <= dreg(33 downto 2);
                        dmi.op   <= dreg(1 downto 0);
                        busy     <= or_reduce(dreg(1 downto 0));
                    end if;
                elsif (I_dmi_response.ack = '1') or (dmihardreset = '1') then -- busy: wait for access termination
                    dmi.data <= I_dmi_response.data;
                    busy     <= '0';
                end if;
             end if; --sreset
        end if; -- posedge
    end process dmi_controller;

    -- DMI output --
    O_dmi_request <= dmi;


end rtl;
