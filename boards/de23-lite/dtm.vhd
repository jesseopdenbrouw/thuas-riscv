-- ================================================================================ --
-- NEORV32 SoC - RISC-V-Compatible Debug Transport Module (DTM)                     --
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
-- different. Still using TRST.


library ieee;
use ieee.std_logic_1164.all;

library work;
use work.processor_common.all;

entity dtm is
    generic (
          IDCODE_VERSION : std_logic_vector(03 downto 0) := "0000"; -- version
          IDCODE_PARTID  : std_logic_vector(15 downto 0) := x"face"; -- part number
          IDCODE_MANID   : std_logic_vector(10 downto 0) := "00000000000" -- manufacturer id
         );
    port (I_clk    : in std_logic;
          I_areset : in std_logic;
          I_sreset : in std_logic;
          -- JTAG connection
          I_trst : in  std_logic;
          I_tck  : in  std_logic;
          I_tms  : in  std_logic;
          I_tdi  : in  std_logic;
          O_tdo  : out std_logic;
          -- Debug Module Interface (DMI)
          O_dmi_request  : out dmi_request_type;
          I_dmi_response : in  dmi_response_type
         );
end dtm;

architecture rtl of dtm is

    -- DMI Configuration
    constant dmi_idle_c    : std_logic_vector(02 downto 0) := "000";    -- no idle cycles required
    constant dmi_version_c : std_logic_vector(03 downto 0) := "0001";   -- debug spec. version (0.13 & 1.0)
    constant dmi_abits_c   : std_logic_vector(05 downto 0) := "000111"; -- number of DMI address bits (7)

    -- TAP data register addresses
    constant addr_idcode_c : std_logic_vector(4 downto 0) := "00001"; -- identifier
    constant addr_dtmcs_c  : std_logic_vector(4 downto 0) := "10000"; -- DTM status and control
    constant addr_dmi_c    : std_logic_vector(4 downto 0) := "10001"; -- debug module interface

    -- TAP JTAG signal synchronizer
    type tap_sync_t is record
        -- Synchronizer shift registers
        trst_ff     : std_logic_vector(2 downto 0);
        tck_ff      : std_logic_vector(2 downto 0);
        tdi_ff      : std_logic_vector(2 downto 0);
        tms_ff      : std_logic_vector(2 downto 0);
        -- Data signals
        trst        : std_logic;
        tck_rising  : std_logic;
        tck_falling : std_logic;
        tdi         : std_logic;
        tms         : std_logic;
    end record;
  signal tap_sync : tap_sync_t;

    -- tap controller states
    type tap_ctrl_state_t is (LOGIC_RESET, DR_SCAN, DR_CAPTURE, DR_SHIFT, DR_EXIT1, DR_PAUSE, DR_EXIT2, DR_UPDATE,
                                 RUN_IDLE, IR_SCAN, IR_CAPTURE, IR_SHIFT, IR_EXIT1, IR_PAUSE, IR_EXIT2, IR_UPDATE);
    signal tap_ctrl_state : tap_ctrl_state_t;

    -- tap registers --
    type tap_reg_t is record
        ireg             : std_logic_vector(04 downto 0);
        bypass           : std_logic;
        idcode           : std_logic_vector(31 downto 0);
        dtmcs, dtmcs_nxt : std_logic_vector(31 downto 0);
        dmi,   dmi_nxt   : std_logic_vector((7+32+2)-1 downto 0); -- 7-bit address + 32-bit data + 2-bit operation
    end record;
    signal tap_reg : tap_reg_t;

    -- update trigger --
    type dr_trigger_t is record
        sreg  : std_logic_vector(1 downto 0);
        valid : std_logic;
    end record;
    signal dr_trigger : dr_trigger_t;

    -- debug module interface controller --
    type dmi_ctrl_t is record
        busy         : std_logic;
        op           : std_logic_vector(01 downto 0);
        dmihardreset : std_logic;
        dmireset     : std_logic;
        err          : std_logic;
        rdata        : std_logic_vector(31 downto 0);
        wdata        : std_logic_vector(31 downto 0);
        addr         : std_logic_vector(06 downto 0);
    end record;
    signal dmi_ctrl : dmi_ctrl_t;

begin

    -- JTAG Input Synchronizer
    tap_synchronizer: process(I_clk, I_areset) is
    begin
        if I_areset = '1' then
            tap_sync.trst_ff <= (others => '0');
            tap_sync.tck_ff  <= (others => '0');
            tap_sync.tdi_ff  <= (others => '0');
            tap_sync.tms_ff  <= (others => '0');
        elsif rising_edge(I_clk) then
            if I_sreset = '1' then
                tap_sync.trst_ff <= (others => '0');
                tap_sync.tck_ff  <= (others => '0');
                tap_sync.tdi_ff  <= (others => '0');
                tap_sync.tms_ff  <= (others => '0');
            else
                tap_sync.trst_ff <= tap_sync.trst_ff(1 downto 0) & I_trst;
                tap_sync.tms_ff  <= tap_sync.tms_ff( 1 downto 0) & I_tms;
                tap_sync.tck_ff  <= tap_sync.tck_ff( 1 downto 0) & I_tck;
                tap_sync.tdi_ff  <= tap_sync.tdi_ff( 1 downto 0) & I_tdi;
            end if;
        end if;
    end process tap_synchronizer;

    -- JTAG reset
    tap_sync.trst <= '0' when (tap_sync.trst_ff(2 downto 1) = "00") else '1';

    -- JTAG clock edge
    tap_sync.tck_rising  <= '1' when (tap_sync.tck_ff(2 downto 1) = "01") else '0';
    tap_sync.tck_falling <= '1' when (tap_sync.tck_ff(2 downto 1) = "10") else '0';

    -- JTAG test mode select
    tap_sync.tms <= tap_sync.tms_ff(2);

    -- JTAG serial data input
    tap_sync.tdi <= tap_sync.tdi_ff(2);


    -- Tap Control FSM
    tap_control: process(I_clk, I_areset)
    begin
        if I_areset = '1' then
            tap_ctrl_state <= LOGIC_RESET;
        elsif rising_edge(I_clk) then
            if I_sreset = '1' then
                tap_ctrl_state <= LOGIC_RESET;
            elsif tap_sync.trst = '0' then -- reset
                tap_ctrl_state <= LOGIC_RESET;
            elsif tap_sync.tck_rising = '1' then -- clock pulse (evaluate TMS on the rising edge of TCK)
                case tap_ctrl_state is -- JTAG state machine
                    when LOGIC_RESET => if tap_sync.tms = '0' then tap_ctrl_state <= RUN_IDLE;   else tap_ctrl_state <= LOGIC_RESET; end if;
                    when RUN_IDLE    => if tap_sync.tms = '0' then tap_ctrl_state <= RUN_IDLE;   else tap_ctrl_state <= DR_SCAN;     end if;
                    when DR_SCAN     => if tap_sync.tms = '0' then tap_ctrl_state <= DR_CAPTURE; else tap_ctrl_state <= IR_SCAN;     end if;
                    when DR_CAPTURE  => if tap_sync.tms = '0' then tap_ctrl_state <= DR_SHIFT;   else tap_ctrl_state <= DR_EXIT1;    end if;
                    when DR_SHIFT    => if tap_sync.tms = '0' then tap_ctrl_state <= DR_SHIFT;   else tap_ctrl_state <= DR_EXIT1;    end if;
                    when DR_EXIT1    => if tap_sync.tms = '0' then tap_ctrl_state <= DR_PAUSE;   else tap_ctrl_state <= DR_UPDATE;   end if;
                    when DR_PAUSE    => if tap_sync.tms = '0' then tap_ctrl_state <= DR_PAUSE;   else tap_ctrl_state <= DR_EXIT2;    end if;
                    when DR_EXIT2    => if tap_sync.tms = '0' then tap_ctrl_state <= DR_SHIFT;   else tap_ctrl_state <= DR_UPDATE;   end if;
                    when DR_UPDATE   => if tap_sync.tms = '0' then tap_ctrl_state <= RUN_IDLE;   else tap_ctrl_state <= DR_SCAN;     end if;
                    when IR_SCAN     => if tap_sync.tms = '0' then tap_ctrl_state <= IR_CAPTURE; else tap_ctrl_state <= LOGIC_RESET; end if;
                    when IR_CAPTURE  => if tap_sync.tms = '0' then tap_ctrl_state <= IR_SHIFT;   else tap_ctrl_state <= IR_EXIT1;    end if;
                    when IR_SHIFT    => if tap_sync.tms = '0' then tap_ctrl_state <= IR_SHIFT;   else tap_ctrl_state <= IR_EXIT1;    end if;
                    when IR_EXIT1    => if tap_sync.tms = '0' then tap_ctrl_state <= IR_PAUSE;   else tap_ctrl_state <= IR_UPDATE;   end if;
                    when IR_PAUSE    => if tap_sync.tms = '0' then tap_ctrl_state <= IR_PAUSE;   else tap_ctrl_state <= IR_EXIT2;    end if;
                    when IR_EXIT2    => if tap_sync.tms = '0' then tap_ctrl_state <= IR_SHIFT;   else tap_ctrl_state <= IR_UPDATE;   end if;
                    when IR_UPDATE   => if tap_sync.tms = '0' then tap_ctrl_state <= RUN_IDLE;   else tap_ctrl_state <= DR_SCAN;     end if;
                    when others      => tap_ctrl_state <= LOGIC_RESET;
                end case;
            end if;
        end if;
    end process tap_control;

    -- trigger for UPDATE state
    update_trigger: process(I_clk, I_areset) is
    begin
        if I_areset = '1' then
            dr_trigger.sreg <= "00";
        elsif rising_edge(I_clk) then
            if I_sreset = '1' then
                dr_trigger.sreg <= "00";
            else
                if tap_ctrl_state = DR_UPDATE then
                    dr_trigger.sreg(0) <= '1';
                else
                    dr_trigger.sreg(0) <= '0';
                end if;
                dr_trigger.sreg(1) <= dr_trigger.sreg(0);
            end if;
        end if;
    end process update_trigger;

    dr_trigger.valid <= '1' when dr_trigger.sreg = "01" else '0';


    -- Tap Register Access
    reg_access: process(I_clk, I_areset) is
    begin
        if I_areset = '1' then
            tap_reg.ireg   <= (others => '0');
            tap_reg.idcode <= (others => '0');
            tap_reg.dtmcs  <= (others => '0');
            tap_reg.dmi    <= (others => '0');
            tap_reg.bypass <= '0';
            O_tdo          <= '0';
        elsif rising_edge(I_clk) then
            if I_sreset = '1' then
                tap_reg.ireg   <= (others => '0');
                tap_reg.idcode <= (others => '0');
                tap_reg.dtmcs  <= (others => '0');
                tap_reg.dmi    <= (others => '0');
                tap_reg.bypass <= '0';
                O_tdo          <= '0';
            else
                -- Serial data input: instruction register
                if tap_ctrl_state = LOGIC_RESET or tap_ctrl_state = IR_CAPTURE then -- preload phase
                    tap_reg.ireg <= addr_idcode_c;
                elsif tap_ctrl_state = IR_SHIFT then -- access phase
                    if tap_sync.tck_rising = '1' then -- [JTAG-SYNC] evaluate TDI on rising edge of TCK
                        tap_reg.ireg <= tap_sync.tdi & tap_reg.ireg(tap_reg.ireg'left downto 1);
                    end if;
                end if;

                -- serial data input: data register
                if tap_ctrl_state = DR_CAPTURE then -- preload phase
                    case tap_reg.ireg is
                        when addr_idcode_c => tap_reg.idcode <= IDCODE_VERSION & IDCODE_PARTID & IDCODE_MANID & '1'; -- identifier (LSB has to be set)
                        when addr_dtmcs_c  => tap_reg.dtmcs  <= tap_reg.dtmcs_nxt; -- status register
                        when addr_dmi_c    => tap_reg.dmi    <= tap_reg.dmi_nxt; -- register interface
                        when others        => tap_reg.bypass <= '0'; -- pass through
                    end case;
                elsif tap_ctrl_state = DR_SHIFT then -- access phase
                    if tap_sync.tck_rising = '1' then -- [JTAG-SYNC] evaluate TDI on rising edge of TCK
                        case tap_reg.ireg is
                            when addr_idcode_c => tap_reg.idcode <= tap_sync.tdi & tap_reg.idcode(tap_reg.idcode'left downto 1);
                            when addr_dtmcs_c  => tap_reg.dtmcs  <= tap_sync.tdi & tap_reg.dtmcs(tap_reg.dtmcs'left downto 1);
                            when addr_dmi_c    => tap_reg.dmi    <= tap_sync.tdi & tap_reg.dmi(tap_reg.dmi'left downto 1);
                            when others        => tap_reg.bypass <= tap_sync.tdi;
                        end case;
                    end if;
                end if;

                -- Serial data output
                if tap_sync.tck_falling = '1' then -- [JTAG-SYNC] update TDO on falling edge of TCK
                    if tap_ctrl_state = IR_SHIFT then
                        O_tdo <= tap_reg.ireg(0);
                    else
                        case tap_reg.ireg is
                            when addr_idcode_c => O_tdo <= tap_reg.idcode(0);
                            when addr_dtmcs_c  => O_tdo <= tap_reg.dtmcs(0);
                            when addr_dmi_c    => O_tdo <= tap_reg.dmi(0);
                            when others        => O_tdo <= tap_reg.bypass;
                        end case;
                    end if;
                end if;
            end if; -- sreset
        end if;  -- posedge
    end process reg_access;

    -- Create next DTMCS
    tap_reg.dtmcs_nxt(31 downto 18) <= (others => '0'); -- reserved
    tap_reg.dtmcs_nxt(17)           <= dmi_ctrl.dmihardreset; -- dmihardreset
    tap_reg.dtmcs_nxt(16)           <= dmi_ctrl.dmireset; -- dmireset
    tap_reg.dtmcs_nxt(15)           <= '0'; -- reserved
    tap_reg.dtmcs_nxt(14 downto 12) <= dmi_idle_c; -- minimum number of idle cycles
    tap_reg.dtmcs_nxt(11 downto 10) <= tap_reg.dmi_nxt(1 downto 0); -- dmistat
    tap_reg.dtmcs_nxt(09 downto 04) <= dmi_abits_c; -- number of DMI address bits
    tap_reg.dtmcs_nxt(03 downto 00) <= dmi_version_c; -- version

    -- DMI register read access
    tap_reg.dmi_nxt(40 downto 34) <= dmi_ctrl.addr; -- address
    tap_reg.dmi_nxt(33 downto 02) <= dmi_ctrl.rdata; -- read data
    tap_reg.dmi_nxt(01 downto 00) <= (others => dmi_ctrl.err); -- status


    -- Debug Module Interface
    dmi_controller: process(I_clk, I_areset) is
    begin
        if I_areset = '1' then
            dmi_ctrl.busy         <= '0';
            dmi_ctrl.op           <= "00";
            dmi_ctrl.dmihardreset <= '1';
            dmi_ctrl.dmireset     <= '0';
            dmi_ctrl.err          <= '0';
            dmi_ctrl.rdata        <= (others => '0');
            dmi_ctrl.wdata        <= (others => '0');
            dmi_ctrl.addr         <= (others => '0');
        elsif rising_edge(I_clk) then
            if I_sreset = '1' then
                dmi_ctrl.busy         <= '0';
                dmi_ctrl.op           <= "00";
                dmi_ctrl.dmihardreset <= '1';
                dmi_ctrl.dmireset     <= '0';
                dmi_ctrl.err          <= '0';
                dmi_ctrl.rdata        <= (others => '0');
                dmi_ctrl.wdata        <= (others => '0');
                dmi_ctrl.addr         <= (others => '0');
            else
                -- DMI reset control
                if dr_trigger.valid = '1' and tap_reg.ireg = addr_dtmcs_c then
                    dmi_ctrl.dmireset     <= tap_reg.dtmcs(16);
                    dmi_ctrl.dmihardreset <= tap_reg.dtmcs(17);
                elsif dmi_ctrl.busy = '0' then
                    dmi_ctrl.dmihardreset <= '0';
                    dmi_ctrl.dmireset     <= '0';
                end if;

                -- Sticky error
                if dmi_ctrl.dmireset = '1' or dmi_ctrl.dmihardreset = '1' then
                    dmi_ctrl.err <= '0';
                elsif dmi_ctrl.busy = '1' and dr_trigger.valid = '1' and tap_reg.ireg = addr_dmi_c then -- access attempt while DMI is busy
                    dmi_ctrl.err <= '1';
                end if;

                -- DMI interface
                dmi_ctrl.op <= dmi_req_nop_c;
                if dmi_ctrl.busy = '0' then
                    if dmi_ctrl.dmihardreset = '0' then
                        if dr_trigger.valid = '1' and tap_reg.ireg = addr_dmi_c then
                            dmi_ctrl.addr  <= tap_reg.dmi(40 downto 34);
                            dmi_ctrl.wdata <= tap_reg.dmi(33 downto 02);
                            if tap_reg.dmi(1 downto 0) = dmi_req_rd_c or tap_reg.dmi(1 downto 0) = dmi_req_wr_c then
                                dmi_ctrl.op   <= tap_reg.dmi(1 downto 0);
                                dmi_ctrl.busy <= '1';
                            end if;
                        end if;
                    end if;
                else -- busy: read/write access in progress
                    dmi_ctrl.rdata <= I_dmi_response.data;
                    if I_dmi_response.ack = '1' then
                        dmi_ctrl.busy <= '0';
                    end if;
                end if;
            end if;  -- sreset
        end if;
    end process dmi_controller;

    -- direct DMI output
    O_dmi_request.op   <= dmi_ctrl.op;
    O_dmi_request.data <= dmi_ctrl.wdata;
    O_dmi_request.addr <= dmi_ctrl.addr;

end rtl;
