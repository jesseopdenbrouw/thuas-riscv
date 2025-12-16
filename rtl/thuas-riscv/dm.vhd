-- #################################################################################################
-- # dm.vhd - Debug Module                                                                         #
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

-- This file contains the Debug Module (DM). The DM can only handle Abstract Commands:
-- Access Registers and Access Memory. Prog mem and system bus are not supported.
-- Register access can also read/write CSRs. Parts based on neorv32 DM module.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.processor_common.all;

-- The Debug Module
entity dm is
    generic (
             -- Do we use address post-increment?
             OCD_AAMPOSTINCREMENT : boolean
            );
    port (I_clk : in std_logic;
          I_areset : in std_logic;
          I_sreset : in std_logic;
          -- Request from DMI (and DTM)
          I_dmi_request : in dmi_request_type;
          O_dmi_response : out dmi_response_type;
          -- State-change signals to/from hart
          O_reset_req : out std_logic;
          I_reset_ack : in std_logic;
          O_halt_req : out std_logic;
          I_halt_ack : in std_logic;
          O_resume_req : out std_logic;
          I_resume_ack : in std_logic;
          O_ackhavereset : out std_logic;
          -- Data exchange with the core
          O_dm_core_data_request : out dm_core_data_request_type;
          I_dm_core_data_response : in dm_core_data_response_type
         );
end entity dm;

architecture rtl of dm is

-- Available DMI registers
constant addr_data0_c        : std_logic_vector(6 downto 0) := "0000100";
constant addr_data1_c        : std_logic_vector(6 downto 0) := "0000101";
constant addr_dmcontrol_c    : std_logic_vector(6 downto 0) := "0010000";
constant addr_dmstatus_c     : std_logic_vector(6 downto 0) := "0010001";
constant addr_hartinfo_c     : std_logic_vector(6 downto 0) := "0010010";
constant addr_abstractcs_c   : std_logic_vector(6 downto 0) := "0010110";
constant addr_command_c      : std_logic_vector(6 downto 0) := "0010111";
constant addr_nextdm_c       : std_logic_vector(6 downto 0) := "0011101";
constant addr_haltsum0_c     : std_logic_vector(6 downto 0) := "1000000";

-- Memory timeout in clock cycles
constant dm_memory_timeout_c : integer := 256;

-- DM version
constant dm_version_c : std_logic_vector(3 downto 0) := "0011";

-- States of the DM
type dmstate_type is (cmd_idle, cmd_check, cmd_preparegprcsr, cmd_preparemem,
                      cmd_readreg1, cmd_readreg2, cmd_writereg1,
                      cmd_readmem1, cmd_writemem1,
                      cmd_error);

type dm_reg_type is record
    dm_active : std_logic;
    ndmreset : std_logic;
    halt_req : std_logic;
    resume_req : std_logic;
    reset_ack : std_logic;
    busy : std_logic;
    read_acc_fault : std_logic;
    write_acc_fault : std_logic;
    illegal_state : std_logic;
    illegal_cmd : std_logic;
    timeout : std_logic;
    data0mustread : std_logic;
    data1mustincrement : std_logic;
    clrerr : std_logic;
    hart_reset : std_logic;
    hart_resume_ack : std_logic;
    hart_halted : std_logic;
    wren : std_logic;
    rden : std_logic;
    --
    data0, data1 : data_type;
    command : data_type;
    cmderr : std_logic_vector(2 downto 0);
    state : dmstate_type;
    counter : integer range 0 to dm_memory_timeout_c-1;
end record;
signal dm_reg : dm_reg_type;

begin

    dm_reg.wren <= '1' when I_dmi_request.op = dmi_req_wr_c else '0';
    dm_reg.rden <= '1' when I_dmi_request.op = dmi_req_rd_c else '0';

    -- Read DM
    process (I_clk, I_areset) is
    begin
        if I_areset = '1' then
            O_dmi_response.data <= (others => '0');
            O_dmi_response.ack <=  '0';
            dm_reg.read_acc_fault <= '0';
        elsif rising_edge(I_clk) then
            if I_sreset = '1' then
                O_dmi_response.data <= (others => '0');
                O_dmi_response.ack <=  '0';
                dm_reg.read_acc_fault <= '0';
            else
                O_dmi_response.data <= (others => '0');
                O_dmi_response.ack <= dm_reg.wren or dm_reg.rden;
                dm_reg.read_acc_fault <= '0';
                if dm_reg.rden = '1' then
                    case I_dmi_request.addr is
                        when addr_dmcontrol_c =>
                            O_dmi_response.data(31 downto 2) <= (others => '0');
                            O_dmi_response.data(1)           <= dm_reg.ndmreset;
                            O_dmi_response.data(0)           <= dm_reg.dm_active;
                        when addr_dmstatus_c =>
                            O_dmi_response.data(31 downto 23) <= (others => '0');     -- reserved (r/-)
                            O_dmi_response.data(22)           <= '0';                 -- impebreak (r/-): no implicit breal
                            O_dmi_response.data(21 downto 20) <= (others => '0');     -- reserved (r/-)
                            O_dmi_response.data(19)           <= I_reset_ack;         -- allhavereset (r/-): there is only one hart that can be reset
                            O_dmi_response.data(18)           <= I_reset_ack;         -- anyhavereset (r/-): there is only one hart that can be reset
                            O_dmi_response.data(17)           <= I_resume_ack;        -- allresumeack (r/-): there is only one hart that can acknowledge resume request
                            O_dmi_response.data(16)           <= I_resume_ack;        -- anyresumeack (r/-): there is only one hart that can acknowledge resume request
                            O_dmi_response.data(15)           <= '0';                 -- allnonexistent (r/-): there is only one hart that is always existent
                            O_dmi_response.data(14)           <= '0';                 -- anynonexistent (r/-): there is only one hart that is always existent
                            O_dmi_response.data(13)           <= dm_reg.ndmreset;     -- allunavail (r/-): there is only one hart that is unavailable during reset
                            O_dmi_response.data(12)           <= dm_reg.ndmreset;     -- anyunavail (r/-): there is only one hart that is unavailable during reset
                            O_dmi_response.data(11)           <= not I_halt_ack;      -- allrunning (r/-): there is only one hart that can be RUNNING or HALTED
                            O_dmi_response.data(10)           <= not I_halt_ack;      -- anyrunning (r/-): there is only one hart that can be RUNNING or HALTED
                            O_dmi_response.data(09)           <= I_halt_ack;          -- allhalted (r/-): there is only one hart that can be RUNNING or HALTED
                            O_dmi_response.data(08)           <= I_halt_ack;          -- anyhalted (r/-): there is only one hart that can be RUNNING or HALTED
                            O_dmi_response.data(07)           <= '1';                 -- authenticated (r/-): authentication passed since there is no authentication
                            O_dmi_response.data(06)           <= '0';                 -- authbusy (r/-): always ready since there is no authentication
                            O_dmi_response.data(05)           <= '0';                 -- hasresethaltreq (r/-): halt-on-reset not implemented
                            O_dmi_response.data(04)           <= '0';                 -- confstrptrvalid (r/-): no configuration string available
                            O_dmi_response.data(03 downto 00) <= dm_version_c;        -- version (r/-): DM spec. version
                        when addr_abstractcs_c =>
                            O_dmi_response.data(31 downto 29) <= (others => '0');     -- reserved
                            O_dmi_response.data(28 downto 24) <= (others => '0');     -- no progbuf
                            O_dmi_response.data(23 downto 13) <= (others => '0');     -- reserved
                            O_dmi_response.data(12)           <= dm_reg.busy;         -- busy
                            O_dmi_response.data(11)           <= '0';                 -- relaxedpriv always 0
                            O_dmi_response.data(10 downto 08) <= dm_reg.cmderr;       -- cmderr
                            O_dmi_response.data(07 downto 04) <= (others => '0');     -- reserved
                            O_dmi_response.data(03 downto 00) <= "0010";              -- number of data registers = 2
                        when addr_data0_c =>
                            O_dmi_response.data <= dm_reg.data0;
                        when addr_data1_c =>
                            O_dmi_response.data <= dm_reg.data1;
                        when addr_haltsum0_c =>
                            O_dmi_response.data <= (0 => I_halt_ack, others => '0');
                        when others =>
                            O_dmi_response.data <= (others => '0');
                    end case;
                    --Read during abstract command executing, see p. 36.
                    if dm_reg.busy = '1' then
                        if I_dmi_request.addr = addr_data0_c or
                           I_dmi_request.addr = addr_data1_c then
                            dm_reg.read_acc_fault <= '1';
                        end if;
                    end if;
                end if;  -- read
            end if;  -- sreset
        end if;  -- posedge
    end process;
    
    -- Write DM
    process (I_clk, I_areset) is
    variable add_v : integer range 0 to 4;
    begin
        if I_areset = '1' then
            dm_reg.halt_req <= '0';
            dm_reg.resume_req <= '0';
            dm_reg.reset_ack <= '0';
            dm_reg.dm_active <= '0';
            dm_reg.ndmreset <= '0';
            dm_reg.clrerr <= '0';
            dm_reg.data0 <= (others => '0');
            dm_reg.data1 <= (others => '0');
            dm_reg.command <= (others => '0');
            dm_reg.write_acc_fault <= '0';
        elsif rising_edge(I_clk) then
            if I_sreset = '1' then
                dm_reg.halt_req <= '0';
                dm_reg.resume_req <= '0';
                dm_reg.reset_ack <= '0';
                dm_reg.dm_active <= '0';
                dm_reg.ndmreset <= '0';
                dm_reg.clrerr <= '0';
                dm_reg.data0 <= (others => '0');
                dm_reg.data1 <= (others => '0');
                dm_reg.command <= (others => '0');
                dm_reg.write_acc_fault <= '0';
            else
                dm_reg.clrerr <= '0';
                dm_reg.resume_req <= '0';
                dm_reg.write_acc_fault <= '0';
                if dm_reg.wren = '1' then
                    case I_dmi_request.addr is
                        when addr_dmcontrol_c =>
                            dm_reg.halt_req   <= I_dmi_request.data(31);                                 -- haltreq (-/w): write 1 to request halt; has to be cleared again by debugger
                            dm_reg.resume_req <= I_dmi_request.data(30) and not I_dmi_request.data(31);  -- resumereq (-/w1): write 1 to request resume; auto-clears
                            dm_reg.reset_ack  <= I_dmi_request.data(28);                                 -- ackhavereset (-/w1): write 1 to ACK reset; auto-clears
                            dm_reg.ndmreset   <= I_dmi_request.data(01);                                 -- ndmreset (r/w): SoC reset when high
                            dm_reg.dm_active  <= I_dmi_request.data(00);                                 -- dmactive (r/w): DM reset when low                    
                        when addr_dmstatus_c => 
                            null;
                        when addr_abstractcs_c =>
                            if I_dmi_request.data(10 downto 8) = "111" then
                                dm_reg.clrerr <= '1';
                            end if;
                        when addr_command_c =>
                            if dm_reg.busy = '0' and dm_reg.cmderr = "000" then -- idle and no errors yet
                                dm_reg.command <= I_dmi_request.data;
                            end if;
                        when addr_data0_c =>
                            dm_reg.data0 <= I_dmi_request.data;
                        when addr_data1_c =>
                            dm_reg.data1 <= I_dmi_request.data;
                        when others =>
                            null;
                    end case;
                    --Write during abstract command executing, see p. 36
                    if dm_reg.busy = '1' then
                        if I_dmi_request.addr = addr_abstractcs_c or
                           I_dmi_request.addr = addr_command_c then
                            dm_reg.write_acc_fault <= '1';
                        end if;
                    end if;
                end if;
                -- Signal that data0 must read the bus (arg0)
                if dm_reg.data0mustread = '1' then
                    dm_reg.data0 <= I_dm_core_data_response.data;
                end if;
                -- When using memory address auto-increment
                if dm_reg.data1mustincrement = '1' then
                    case dm_reg.command(22 downto 20) is
                        when "000"  => add_v := 1;
                        when "001"  => add_v := 2;
                        when "010"  => add_v := 4;
                        when others => add_v := 0;
                    end case;
                    dm_reg.data1 <= std_logic_vector(unsigned(dm_reg.data1) + add_v);
                end if;  -- write
            end if;  -- sreset
        end if; -- posedge
    end process;
    
    -- DM state machine
    process (I_clk, I_areset) is
    begin
        if I_areset = '1' then
            dm_reg.state <= cmd_idle;
            dm_reg.cmderr <= "000";
            dm_reg.illegal_state <= '0';
            dm_reg.illegal_cmd <= '0';
            dm_reg.timeout <= '0';
            dm_reg.counter <= 0;
            -- Reset the bus to the core
            O_dm_core_data_request.stb <= '0';
            O_dm_core_data_request.readcsr <= '0';
            O_dm_core_data_request.writecsr <= '0';
            O_dm_core_data_request.readgpr <= '0';
            O_dm_core_data_request.writegpr <= '0';
            O_dm_core_data_request.writemem <= '0';
            O_dm_core_data_request.readmem <= '0';
            O_dm_core_data_request.address <= (others =>'0');
            O_dm_core_data_request.data <= (others => '0');
        elsif rising_edge(I_clk) then
            dm_reg.illegal_state <= '0';
            dm_reg.illegal_cmd <= '0';
            dm_reg.timeout <= '0';
            if I_sreset = '1' then
                dm_reg.state <= cmd_idle;
                dm_reg.cmderr <= "000";
                dm_reg.counter <= 0;
                -- Reset the bus to the core
                O_dm_core_data_request.stb <= '0';
                O_dm_core_data_request.readcsr <= '0';
                O_dm_core_data_request.writecsr <= '0';
                O_dm_core_data_request.readgpr <= '0';
                O_dm_core_data_request.writegpr <= '0';
                O_dm_core_data_request.writemem <= '0';
                O_dm_core_data_request.readmem <= '0';
                O_dm_core_data_request.address <= (others =>'0');
                O_dm_core_data_request.data <= (others => '0');
            else
                -- If the DM is deactivated...
                if dm_reg.dm_active = '0' then
                    dm_reg.state <= cmd_idle;
                    dm_reg.counter <= 0;
                    -- Reset the bus to the core
                    O_dm_core_data_request.stb <= '0';
                    O_dm_core_data_request.readcsr <= '0';
                    O_dm_core_data_request.writecsr <= '0';
                    O_dm_core_data_request.readgpr <= '0';
                    O_dm_core_data_request.writegpr <= '0';
                    O_dm_core_data_request.readmem <= '0';
                    O_dm_core_data_request.writemem <= '0';
                    O_dm_core_data_request.address <= (others =>'0');
                    O_dm_core_data_request.data <= (others => '0');
                else
                    case dm_reg.state is
                        -- Idle, wait for command to be written
                        when cmd_idle =>
                            O_dm_core_data_request.stb <= '0';
                            O_dm_core_data_request.readcsr <= '0';
                            O_dm_core_data_request.writecsr <= '0';
                            O_dm_core_data_request.readgpr <= '0';
                            O_dm_core_data_request.writegpr <= '0';
                            O_dm_core_data_request.readmem <= '0';
                            O_dm_core_data_request.writemem <= '0';
                            O_dm_core_data_request.address <= (others => '0');
                            O_dm_core_data_request.data <= (others => '0');
                            if dm_reg.wren  = '1' and I_dmi_request.addr = addr_command_c and dm_reg.cmderr = "000" then
                                -- Command issued
                                dm_reg.state <= cmd_check;
                            end if;
                        -- Check the command and dispatch. Commands are: register access end memory access.
                        when cmd_check =>
                            if dm_reg.command(31 downto 24) = x"00" and     -- register access
                               dm_reg.command(23) = '0' and 
                               dm_reg.command(22 downto 20) = "010" and     -- 32 bits access only
                               dm_reg.command(19) = '0' and                 -- no post-increment
                               dm_reg.command(17) = '1' then                -- transfer request
                                if I_halt_ack = '1' then                    -- check halted
                                    dm_reg.state <= cmd_preparegprcsr;
                                else
                                    dm_reg.illegal_state <= '1';
                                    dm_reg.state <= cmd_error;
                                end if;
                            elsif dm_reg.command(31 downto 24) = x"02" and              -- memory access
                                  dm_reg.command(23) = '0' and
                                 (dm_reg.command(22 downto 20) = "000" or               -- 8-bit access
                                  dm_reg.command(22 downto 20) = "001" or               -- 16-bit access
                                  dm_reg.command(22 downto 20) = "010") and             -- 32-bit access
                                 (dm_reg.command(19) = '0' or OCD_AAMPOSTINCREMENT) and -- (no) post-increment
                                  dm_reg.command(18) = '0' and
                                  dm_reg.command(17) = '0' then
                                if I_halt_ack = '1' then                    -- check halted
                                    dm_reg.state <= cmd_preparemem;
                                else
                                    dm_reg.illegal_state <= '1';
                                    dm_reg.state <= cmd_error;
                                end if;
                            else
                                dm_reg.illegal_cmd <= '1';
                                dm_reg.state <= cmd_error;
                            end if;
                        -- Prepare for executing command GPR and CSR
                        when cmd_preparegprcsr =>
                            if dm_reg.command(17) = '1' then                -- transfer
                                if dm_reg.command(16) = '0' then            -- read
                                    O_dm_core_data_request.address <= x"0000" & dm_reg.command(15 downto 0);
                                    O_dm_core_data_request.readcsr <= not dm_reg.command(12); -- csr bit 12 = 0 (0x0yyy)
                                    O_dm_core_data_request.readgpr <= dm_reg.command(12); -- gpr bit 12 = 1   (0x1yyy)
                                    dm_reg.state <= cmd_readreg1;
                                else                                        -- write
                                    O_dm_core_data_request.address <= x"0000" & dm_reg.command(15 downto 0);
                                    O_dm_core_data_request.data <= dm_reg.data0;
                                    O_dm_core_data_request.writecsr <= not dm_reg.command(12); -- csr bit 12 = 0 (0x0yyy)
                                    O_dm_core_data_request.writegpr <= dm_reg.command(12); -- gpr bit 12 = 1 (0x1yyy)
                                    dm_reg.state <= cmd_writereg1;
                                end if;
                            else
                                dm_reg.state <= cmd_idle;
                            end if;
                        -- Reading a register takes two cycles, this is cycle 1
                        when cmd_readreg1 =>
                            dm_reg.state <= cmd_readreg2;
                        -- Reading a register takes two cycles, this is cycle 2
                        -- Note that a CSR is actually accessed twice, that is not a problem
                        -- because none of the CSRs have side effects
                        -- In this cycle, data0 is loaded with external data
                        when cmd_readreg2 =>
                            dm_reg.state <= cmd_idle;
                        -- Writes take 1 cycle for csr, 2 for registers
                        when cmd_writereg1 =>
                            O_dm_core_data_request.writecsr <= '0';
                            O_dm_core_data_request.address <= (others => '0');
                            O_dm_core_data_request.data <= (others => '0');
                            dm_reg.state <= cmd_idle;
                        -- Prepare DM for memory access
                        when cmd_preparemem =>
                            O_dm_core_data_request.stb <= '1';
                            O_dm_core_data_request.address <= dm_reg.data1;
                            O_dm_core_data_request.data <= dm_reg.data0;
                            O_dm_core_data_request.size <= dm_reg.command(21 downto 20);
                            dm_reg.counter <= dm_memory_timeout_c-1;
                            if dm_reg.command(16) = '0' then            -- read
                                O_dm_core_data_request.writemem <= '0';
                                O_dm_core_data_request.readmem <= '1';
                                dm_reg.state <= cmd_readmem1;
                            else
                                O_dm_core_data_request.writemem <= '1';
                                O_dm_core_data_request.readmem <= '0';
                                dm_reg.state <= cmd_writemem1;
                            end if;
                        -- Read memory, wait for response
                        when cmd_readmem1 =>
                            O_dm_core_data_request.stb <= '0';
                            if I_dm_core_data_response.ack = '1' then
                                dm_reg.state <= cmd_idle;
                            end if;
                            -- Timeout counter, if it times out, the memory
                            -- operation did not succeed and an error is
                            -- reported to the debugger. This keeps the DM
                            -- operable.
                            if dm_reg.counter > 0 then
                                dm_reg.counter <= dm_reg.counter - 1;
                            else
                                dm_reg.timeout <= '1';
                                dm_reg.state <= cmd_error;
                            end if;
                        -- Write memory, wait for response
                        when cmd_writemem1 =>
                            O_dm_core_data_request.stb <= '0';
                            -- One-shot writemem
                            O_dm_core_data_request.writemem <= '0';
                            if I_dm_core_data_response.ack = '1' then
                                dm_reg.state <= cmd_idle;
                            end if;
                            -- Timeout counter, if it times out, the memory
                            -- operation did not succeed and an error is
                            -- reported to the debugger. This keeps the DM
                            -- operable.
                            if dm_reg.counter > 0 then
                                dm_reg.counter <= dm_reg.counter - 1;
                            else
                                dm_reg.timeout <= '1';
                                dm_reg.state <= cmd_error;
                            end if;
                        -- Extra cycle to get cmderr in place
                        when cmd_error =>
                            dm_reg.state <= cmd_idle;
                        when others =>
                            dm_reg.state <= cmd_idle;
                    end case;
                end if;
                -- Command error processing
                if dm_reg.cmderr = "000" then
                    -- CPU not in halt
                    if dm_reg.illegal_state = '1' then
                        dm_reg.cmderr <= "100";
                    -- Illegal command supplied
                    elsif dm_reg.illegal_cmd = '1' then
                        dm_reg.cmderr <= "010";
                    -- Timeout on memory operation (== bus error)
                    elsif dm_reg.timeout = '1' then
                        dm_reg.cmderr <= "101";
                    -- Exception (illegal_instruction == use illegal register)
                    elsif I_dm_core_data_response.excep = '1' then
                        dm_reg.cmderr <= "011";
                    -- Bus error (misaligned etc)
                    elsif I_dm_core_data_response.buserr = '1' then
                        dm_reg.cmderr <= "101";
                    -- Read or write access during request
                    elsif dm_reg.read_acc_fault = '1' or dm_reg.write_acc_fault = '1' then
                        dm_reg.cmderr <= "001";
                    end if;
                elsif dm_reg.clrerr = '1' then
                    dm_reg.cmderr <= "000";
                end if;
            end if;  -- sreset
        end if;  -- posedge
    end process;
    
    -- Set busy flag
    dm_reg.busy <= '0' when dm_reg.state = cmd_idle else '1';
    -- data0 must read data from the bus
    dm_reg.data0mustread <= '1' when dm_reg.state = cmd_readreg2 or (dm_reg.state = cmd_readmem1 and I_dm_core_data_response.ack = '1') else '0';
    -- data1 must increment or not
    dm_reg.data1mustincrement <= '1' when OCD_AAMPOSTINCREMENT and dm_reg.command(19) = '1' and (dm_reg.state = cmd_writemem1 or dm_reg.state = cmd_readmem1) and I_dm_core_data_response.ack = '1' else '0';

    O_halt_req <= dm_reg.halt_req and dm_reg.dm_active;
    O_resume_req <= dm_reg.resume_req and dm_reg.dm_active;
    O_reset_req <= dm_reg.ndmreset and dm_reg.dm_active;
    O_ackhavereset <= dm_reg.reset_ack and dm_reg.dm_active;
    
end architecture rtl;