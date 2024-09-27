-- #################################################################################################
-- # core.vhd - The processor core                                                                 #
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

-- This file contains the description of a RISC-V RV32IM core,
-- using a three-stage pipeline. It contains the PC, the
-- instruction decoder and the ALU, the MD unit, the memory
-- interface unit, the CSR and the LIC.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.processor_common.all;

entity core is
    generic (
          -- The frequency of the system
          SYSTEM_FREQUENCY : integer;
          -- Hardware version in BCD
          HW_VERSION : integer;
          -- Do we have on-chip debugger (OCD)?
          HAVE_OCD : boolean;
          -- If bootloader enabled, adjust the boot address
          HAVE_BOOTLOADER_ROM : boolean;
          -- Disable CSR address check when in debug mode
          OCD_CSR_CHECK_DISABLE : boolean;
          -- RISCV E (embedded) of RISCV I (full)
          HAVE_RISCV_E : boolean;
          -- Do we have the integer multiply/divide unit?
          HAVE_MULDIV : boolean;
          -- Fast divide (needs more area)?
          FAST_DIVIDE : boolean;
          -- Do we have Zba (sh?add)
          HAVE_ZBA : boolean;
          -- Do we have Zbs (bit instructions)?
          HAVE_ZBS : boolean;
          -- Do we have Zicond (czero.{eqz|nez})?
          HAVE_ZICOND : boolean;
          -- Do we have HPM counters?
          HAVE_ZIHPM : boolean;
          -- Do we enable vectored mode for mtvec?
          VECTORED_MTVEC : boolean;
          -- Do we have registers is RAM?
          HAVE_REGISTERS_IN_RAM : boolean;
          -- 4 high bits of ROM address
          ROM_HIGH_NIBBLE : memory_high_nibble;
          -- 4 high bits of boot ROM address
          BOOT_HIGH_NIBBLE : memory_high_nibble;
          -- Do we have fast store?
          HAVE_FAST_STORE : boolean;
          -- Do we have UART1?
          HAVE_UART1 : boolean;
          -- Do we have SPI1?
          HAVE_SPI1 : boolean;
          -- Do we have SPI2?
          HAVE_SPI2 : boolean;
          -- Do we have I2C1?
          HAVE_I2C1 : boolean;
          -- Do we have I2C2?
          HAVE_I2C2 : boolean;
          -- Do we have TIMER1?
          HAVE_TIMER1 : boolean;
          -- Do we have TIMER2?
          HAVE_TIMER2 : boolean;
          -- use watchdog?
          HAVE_WDT : boolean;
          -- UART1 BREAK triggers system reset
          UART1_BREAK_RESETS : boolean
         );
    port (I_clk : in std_logic;
          I_areset : in std_logic;
          -- Instruction request from ROM
          O_instr_request : out instr_request_type;
          I_instr_response : in instr_response_type;
          -- To and from memory
          O_bus_request : out bus_request_type;
          I_bus_response : in bus_response_type;
          -- Interrupt signals from I/O
          I_intrio : data_type;
          -- [m]time from the memory mapped I/O
          I_mtime : in data_type;
          I_mtimeh : in data_type;
          -- Debug signals
          I_dm_core_data_request : in dm_core_data_request_type;
          O_dm_core_data_response : out dm_core_data_response_type;
          I_halt_req : in std_logic;
          I_resume_req : in std_logic;
          I_ackhavereset : in std_logic;
          O_halt_ack : out std_logic;
          O_reset_ack : out std_logic;
          O_resume_ack : out std_logic
         );
end entity core;

architecture rtl of core is

-- The Program Counter
-- Not part of any record.
signal pc : data_type;

-- IF/ID signals for Instruction Decode stage
type if_id_type is record
    pc : data_type;
end record if_id_type;
signal if_id : if_id_type;

-- ID/EX signals for Execute stage
-- Behavior of the Program Counter
type pc_op_type is (pc_hold, pc_incr, pc_loadoffset, pc_loadoffsetregister,
                    pc_branch, pc_load_mepc, pc_load_mtvec);
type id_ex_type is record
    instr : data_type;
    alu_op : alu_op_type;
    rd : reg_type;
    rd_en : std_logic;
    rs1 : reg_type;
    rs2 : reg_type;
    rs1data : data_type;
    rs2data : data_type;
    imm : data_type;
    isimm : std_logic;
    isunsigned : std_logic;
    ismem : std_logic;
    md_op : func3_type;
    md_start : std_logic;
    memaccess : memaccess_type;
    memsize : memsize_type;
    pc_op : pc_op_type;
    pc : data_type;
    csr_op : csr_op_type;
    csr_addr : std_logic_vector(11 downto 0);
    csr_immrs1 : std_logic_vector(4 downto 0);
    -- The result is not clocked and really should be in ex_wb...
    result : data_type;
end record id_ex_type;
signal id_ex : id_ex_type;

-- EX/WB for Write Back stage
type ex_wb_type is record
    rd : reg_type;
    rd_en : std_logic;
    rddata : data_type;
    pc : data_type;
end record ex_wb_type;
signal ex_wb : ex_wb_type;

-- The registers
-- Number of registers: 16 for E, 32 for I
constant NUMBER_OF_REGISTERS : integer := get_int_from_boolean(HAVE_RISCV_E, 16, 32);
type regs_array_type is array (0 to NUMBER_OF_REGISTERS-1) of data_type;
-- Quartus will not generate RAM blocks for registers when they are in a record
-- Also, Quartus will not generate RAM blocks when one set of registers is to be copied three times
signal regs_rs1, regs_rs2, regs_debug : regs_array_type;
-- Do not check for read during write. For some reason, Quartus
-- thinks that there are asynchronous read and write clocks.
attribute ramstyle : string;
attribute ramstyle of regs_rs1 : signal is "no_rw_check";
attribute ramstyle of regs_rs2 : signal is "no_rw_check";
attribute ramstyle of regs_debug : signal is "no_rw_check";
signal selrs1 : integer range 0 to NUMBER_OF_REGISTERS-1;
signal selrs2 : integer range 0 to NUMBER_OF_REGISTERS-1;
-- Used with on-chip debugger
signal data_from_gpr : data_type;


-- Control signals
-- States of the controller
type state_type is (state_boot0, state_boot1, state_exec, state_mem,
                    state_flush, state_flush2, state_md, state_md2,
                    state_trap, state_trap2, state_trap3, state_mret,
                    state_mret2, state_wfi, state_debug, state_debugflush,
                    state_debugflush2, state_debugflush3);
type control_type is record
    -- Stall, flush, jump/branch, instructions retired
    stall : std_logic;
    flush : std_logic;
    penalty : std_logic;
    instret : std_logic;
    indebug : std_logic;
    step : std_logic;
    bpmatch : std_logic;
    stall_on_trigger : std_logic;
    load_pc : std_logic;
    load_dpc : std_logic;
    skip_match : std_logic;
    isstepping : std_logic;
    -- The state of the controller
    state : state_type;
    -- Forwarding latest result
    forwarda : std_logic;
    forwardb : std_logic;
    -- Write x0 with 0 at startup if regs are in RAM
    reg0_write_once : std_logic;
    -- Instruction problem
    illegal_instruction_decode : std_logic;
    illegal_instruction_csr : std_logic;
    instruction_misaligned : std_logic;
    instr_access_error : std_logic_vector(1 downto 0);
    instr_misaligned_ff : std_logic;
    -- Instructions concerning traps
    ecall_request : std_logic;
    ebreak_request : std_logic;
    mret_request : std_logic;
    wfi_request : std_logic;
    mret_request_delay : std_logic;
    -- Trap hardware
    trap_request : std_logic;
    trap_release : std_logic;
    trap_mcause : data_type;
    may_interrupt : std_logic;
end record control_type;
signal control : control_type;

-- Multiplier/divider
type md_type is record
    -- Operation ready
    ready : std_logic;
    -- Multiplier
    rdata_a, rdata_b : unsigned(32 downto 0);
    mul_rd_int : signed(65 downto 0);
    mul_running : std_logic;
    mul_ready : std_logic;
    mul : data_type;
    -- Divider
    buf : unsigned(63 downto 0);
    divisor : unsigned(31 downto 0);
    divisor1: unsigned(33 downto 0);
    divisor2: unsigned(33 downto 0);
    divisor3: unsigned(33 downto 0);
    quotient : unsigned(31 downto 0);
    remainder : unsigned(31 downto 0);
    outsign : std_logic;
    div_ready : std_logic;
    div : data_type;
    count: integer range 0 to 32;
end record md_type;
signal md : md_type;
alias md_buf1 is md.buf(63 downto 32);
alias md_buf2 is md.buf(31 downto 0);

-- The Control and Status Registers
-- Keep csr_size_bits to 12!!!
-- The CSRs have their own address space, it is not
-- visible on the 4 GB normal address space.
constant csr_size_bits : integer := 12;
constant csr_size : integer := 2**csr_size_bits;

-- CSR access of registers
type csr_access_type is record
    address : std_logic_vector(11 downto 0);
    op : csr_op_type;
    immrs1 : std_logic_vector(4 downto 0);
    dataout : data_type;
    datain : data_type;
end record csr_access_type;
signal csr_access : csr_access_type;

-- CSR registers
type csr_reg_type is record
    mvendorid : data_type;
    marchid : data_type;
    mimpid : data_type;
    mhartid : data_type;
    mstatus : data_type;
    misa : data_type;
    mie : data_type;
    mtvec : data_type;
    mstatush : data_type;
    mcountinhibit : data_type;
    mscratch : data_type;
    mepc : data_type;
    mcause : data_type;
    mtval : data_type;
    mip : data_type;
    mcycle : data_type;
    mcycleh : data_type;
    mtime : data_type;
    mtimeh : data_type;
    minstret : data_type;
    minstreth : data_type;
    mconfigptr : data_type;
    mhpmcounter3 : data_type;
    mhpmcounter3h : data_type;
    mhpmevent3 : data_type;
    mhpmcounter4 : data_type;
    mhpmcounter4h : data_type;
    mhpmevent4 : data_type;
    mhpmcounter5 : data_type;
    mhpmcounter5h : data_type;
    mhpmevent5 : data_type;
    mhpmcounter6 : data_type;
    mhpmcounter6h : data_type;
    mhpmevent6 : data_type;
    mhpmcounter7 : data_type;
    mhpmcounter7h : data_type;
    mhpmevent7 : data_type;
    mhpmcounter8 : data_type;
    mhpmcounter8h : data_type;
    mhpmevent8 : data_type;
    mhpmcounter9 : data_type;
    mhpmcounter9h : data_type;
    mhpmevent9 : data_type;
    mxhw : data_type;
    mxspeed : data_type;
    dcsr : data_type;
    dpc : data_type;
    tselect : data_type;
    tdata1 : data_type;
    tdata2 : data_type;
    tinfo : data_type;
    dcsr_cause : std_logic_vector(3 downto 0);
end record csr_reg_type;
signal csr_reg : csr_reg_type;

-- For transfering data between CSR and the PC
type csr_transfer_type is record
    mtvec_to_pc : data_type;
    mepc_to_pc : data_type;
    address_to_mtval : data_type;
end record csr_transfer_type;
signal csr_transfer : csr_transfer_type;

begin

    --
    -- Control block:
    -- This block holds the current processing state of the
    -- processor and supplies the control signals to the
    -- other blocks.
    --
    
    
    -- Hardware breakpoint match
    control.bpmatch <= '1' when id_ex.pc = csr_reg.tdata2 and                   -- instruction address match
                                csr_reg.tdata1(6) = '1' and                     -- and M mode
                                csr_reg.tdata1(2) = '1' and                     -- and EXECUTE
                                csr_reg.tdata1(15 downto 12) = "0001" and       -- and enter debug mode
                                csr_reg.tdata1(10 downto 07) = "0000" else      -- and match equal   
                       '0'; 

    -- Processor state control
    process (I_clk, I_areset) is
    begin
        if I_areset = '1' then
            control.state <= state_boot0;
            control.step <= '0';
            O_halt_ack <= '0';
            O_reset_ack <= '0';
            O_resume_ack <= '0';
            control.load_pc <= '0';
            control.load_dpc <= '0';
            control.skip_match <= '0';
            csr_reg.dcsr_cause <= "0000";
        elsif rising_edge(I_clk) then
            control.load_pc <= '0';
            control.load_dpc <= '0';
            if I_ackhavereset = '1' then
                O_reset_ack <= '0';
            end if;
            case control.state is
                -- Booting first cycle
                when state_boot0 =>
                    control.state <= state_boot1;
                    control.skip_match <= '0';
                    control.step <= '0';
                    O_halt_ack <= '0';
                    O_reset_ack <= '0';
                    O_resume_ack <= '0';
                    csr_reg.dcsr_cause <= "0000";
                -- Booting second cycle
                when state_boot1 =>
                    control.state <= state_exec;
                    O_reset_ack <= '1';
                -- The executing state, can be interrupted.
                when state_exec =>
                    O_resume_ack <= '1';  -- keep this at '1'
                    O_halt_ack <= '0';

                    -- If user halt request...
                    if I_halt_req = '1' and HAVE_OCD then
                        O_halt_ack <= '1';                  -- Signal halt
                        control.step <= '0';                --
                        control.state <= state_debug;       -- Goto to debug state
                        control.load_dpc <= '1';            -- Load DPC with PC
                        csr_reg.dcsr_cause <= "1011";       -- Signal halt to user
                    -- If hardware breakpoint and not resuming from this breakpoint...
                    elsif control.bpmatch = '1' and control.skip_match = '0' and HAVE_OCD then
                        O_halt_ack <= '1';                  -- Signal halt
                        control.step <= '0';                --
                        control.state <= state_debug;       -- Goto debug state
                        control.load_dpc <= '1';            -- Load DPC with PC
                        csr_reg.dcsr_cause <= "1010";       -- Signal HW break to user
                    -- If software breakpoint...
                    -- Can be switched off with: <targetname> riscv set_ebreakm off
                    -- dcsr(15) is dcsr.ebreakm bit
                    elsif control.ebreak_request = '1' and csr_reg.dcsr(15) = '1' and HAVE_OCD then
                        O_halt_ack <= '1';                  -- Signal halt
                        control.step <= '0';                --
                        control.state <= state_debug;       -- Goto debug state
                        control.load_dpc <= '1';            -- Load DPC with PC
                        csr_reg.dcsr_cause <= "1001";       -- Signal EBREAK to user
                    elsif control.isstepping = '1' and control.step = '0' and HAVE_OCD then
                        O_halt_ack <= '1';                  -- Signal halt
                        control.step <= '0';
                        control.state <= state_debug;       -- Goto debug state
                        control.load_dpc <= '1';            -- Load DPC with PC
                        csr_reg.dcsr_cause <= "1100";       -- Signal STEP to user
                    -- If there is a trap request, it can be an interrupt
                    -- or an exception.
                    elsif control.trap_request = '1' then
                        control.state <= state_trap;
                    elsif control.wfi_request = '1' then----
                        control.state <= state_wfi;
                    -- If we have an mret request (MRET)
                    elsif control.mret_request = '1' then
                        control.state <= state_mret;
                    -- Jump/branch request
                    elsif control.penalty = '1' then
                        control.state <= state_flush;
                    -- If we have to wait for data, we need to wait extra cycles
                    elsif id_ex.ismem = '1' and I_bus_response.ready = '0' then
                        control.state <= state_mem;
                    -- If the MD unit is started....
                    elsif id_ex.md_start = '1' then
                        control.state <= state_md;
                    end if;
                    control.step <= '0';

                -- Wait for data (read from ROM, boot ROM, RAM or I/O)
                when state_mem =>
                    -- If there is a trap then it is one of load/store misaligned error
                    -- This can never be an interrupt, because interrupts are disabled
                    -- while accessing memory
                    if control.trap_request = '1' then
                        control.state <= state_trap;
                    elsif I_bus_response.ready = '1' then
                        control.state <= state_exec;
                    end if;
                -- Flush
                when state_flush =>
                    control.state <= state_flush2;
                -- Second state flush
                when state_flush2 =>
                    control.state <= state_exec;
                -- Flush after leaving debug state
                when state_debugflush =>
                    control.state <= state_debugflush2;
                when state_debugflush2 =>
                    control.state <= state_debugflush3;
                when state_debugflush3 =>
                    control.state <= state_exec;
                -- MD operation in progress (cannot be interrupted)
                when state_md =>
                    if md.ready = '1' then
                        control.state <= state_md2;
                    end if;
                -- MD ready, copy result (cannot be interrupted)
                when state_md2 =>
                    control.state <= state_exec;
                -- First cycle of trap request, flushes pipeline
                when state_trap =>
                    control.state <= state_trap2;
                -- Second state of trap handling, flushes pipeline
                when state_trap2 =>
                    if control.isstepping = '1' then
                        control.state <= state_trap3;
                    else
                        control.state <= state_exec;
                    end if;
                -- Need this extra state to load the correct PC in DPC
                when state_trap3 =>
                    control.state <= state_exec;
                -- First state of MRET, flushes the pipeline
                when state_mret =>
                    control.state <= state_mret2;
                -- Second state of MRET, flushes the pipeline
                when state_mret2 =>
                    control.state <= state_exec;
                -- Stalling on WFI, waiting for an interrupt
                when state_wfi =>
                    -- A halt request on WFI goes to debug state
                    if I_halt_req = '1' and HAVE_OCD then
                        O_halt_ack <= '1';                  -- Signal halt
                        control.step <= '0';                --
                        control.state <= state_debug;       -- Goto to debug state
                        control.load_dpc <= '1';            -- Load DPC with PC
                        csr_reg.dcsr_cause <= "1011";       -- Signal halt to user                  
                    elsif control.trap_request = '1' then
                        control.state <= state_trap;
                    end if;
                -- When we're in debug...
                when state_debug =>
                    csr_reg.dcsr_cause <= "0000";
                    O_halt_ack <= '1';
                    -- If resuming from stepping
                    if I_resume_req = '1' and control.isstepping = '1' then
                        control.state <= state_debugflush;   -- Flush the pipeline
                        control.step <= '1';            -- Set stepping
                        csr_reg.dcsr_cause <= "1000";   -- Clear DCSR.cause
                        control.load_pc <= '1';         -- Load PC with DPC
                        O_halt_ack <= '0';              -- Signal run
                        control.skip_match <= control.bpmatch;
                    elsif I_resume_req = '1' then
                        control.state <= state_debugflush;   -- Flush the pipeline
                        control.step <= '0';            -- Not stepping
                        csr_reg.dcsr_cause <= "1000";   -- Clear DCSR.cause
                        control.load_pc <= '1';         -- Load PC with DPC
                        O_halt_ack <= '0';              -- Signal run
                        control.skip_match <= control.bpmatch;
                    end if;
                when others =>
                    control.state <= state_exec;
            end case;
        end if;
    end process;
    
    -- Determine stall
    -- We need to stall if we...
    control.stall <= '1' when (control.state = state_exec and id_ex.ismem = '1' and I_bus_response.ready = '0') or
                              (control.state = state_md) or
                              (control.state = state_wfi) or
                              (control.state = state_mem and I_bus_response.ready = '0') or
                              (control.state = state_exec and id_ex.md_start = '1')
                         else '0';
    -- If we got a trigger (breakpoint (hw/sw) or step)
    control.stall_on_trigger <= '1' when (control.state = state_exec and I_halt_req = '1' and HAVE_OCD) or
                                         (control.state = state_exec and control.bpmatch = '1' and control.skip_match = '0' and HAVE_OCD) or
                                         (control.state = state_exec and control.ebreak_request = '1' and csr_reg.dcsr(15) = '1' and HAVE_OCD) or
                                         (control.state = state_debug and HAVE_OCD) or
                                         (control.state = state_exec and control.isstepping = '1' and control.step = '0' and HAVE_OCD)
                                    else '0';

    -- Needed for the instruction fetch for the ROM or boot ROM
    O_instr_request.stall <= control.stall or control.stall_on_trigger;

    -- We need to flush if we are jumping/branching or servicing interrupts
    control.flush <= '1' when control.penalty = '1' or
                              control.state = state_flush or
                              control.state = state_debugflush or
                              control.state = state_trap or 
                              control.state = state_trap2 or
                              control.state = state_mret or
                              control.state = state_boot0
                         else '0'; -- for now

    -- Instructions retired -- not exact, needs more detail
    control.instret <= '1' when (control.state = state_exec and control.trap_request = '0' and id_ex.ismem = '0'
                                                            and id_ex.md_start = '0' and control.penalty = '0'
                                                            and control.mret_request = '0' and I_halt_req = '0'
                                                            and control.bpmatch = '0' and control.ebreak_request = '0'
                                                            and control.stall_on_trigger = '0') or
                                 (control.state = state_mem and I_bus_response.ready = '1') or
                                  control.state = state_md2 or
                                  control.state = state_flush2 or
                                  control.state = state_mret2
                           else '0'; 
                                    
    -- We're in debug
    control.indebug <= '1' when control.state = state_debug else '0';
    
    -- We're stepping
    control.isstepping <= '1' when csr_reg.dcsr(2) = '1' else '0';
    
    -- Delay the release request (for use in the CSR)
    control.mret_request_delay <= '1' when control.state = state_mret2 else '0';
    
    -- May the core be interrupted (only for interrupts, not exceptions)?
    control.may_interrupt <= '1' when control.state = state_exec or control.state = state_wfi else '0';
    
    -- Check if the currently executing instruction address is aligned to word
    -- We need to make a one-shot, because the PC is incremented by 4 each clock
    -- cycle so the pipeline PCs will all be misaligned and the misaligned signal
    -- would be multiple clock cycles which messes up trap entry.
    process (I_clk, I_areset) is
    begin
        if I_areset = '1' then
            control.instr_misaligned_ff <= '0';
        elsif rising_edge(I_clk) then
            if id_ex.pc(1 downto 0) /= "00" then
                control.instr_misaligned_ff <= '1';
            else
                control.instr_misaligned_ff <= '0';
            end if;
        end if;
    end process;
    control.instruction_misaligned <= '1' when id_ex.pc(1 downto 0) /= "00" and control.instr_misaligned_ff = '0' else '0';
            
    -- Delay instruction access (read) error) for two cycles so that
    -- the faulted address/instruction is being processed in the
    -- execute stage.
    process (I_clk, I_areset) is
    begin
        if I_areset = '1' then
            control.instr_access_error <= (others => '0');
        elsif rising_edge(I_clk) then
            if control.state = state_trap then
                control.instr_access_error <= (others => '0');
            else
                control.instr_access_error <= control.instr_access_error(0) & I_instr_response.instr_access_error;
            end if;
        end if;
    end process;
    

    -- Data forwarder. Forward RS1/RS2 if they are used in current instruction,
    -- and were written in the previous instruction.
    process (id_ex, ex_wb) is
    begin
        if ex_wb.rd_en = '1' and ex_wb.rd = id_ex.rs1 then
            control.forwarda <= '1';
        else
            control.forwarda <= '0';
        end if;
        if ex_wb.rd_en = '1' and ex_wb.rd = id_ex.rs2 then
            control.forwardb <= '1';
        else
            control.forwardb <= '0';
        end if;
    end process;


    --
    -- Instruction fetch block
    -- This block controls the instruction fetch from the ROM.
    -- It also instructs the PC to load a new address, either
    -- the next sequential address or a jump target address.
    --
    
    -- The PC
    process (I_clk, I_areset) is
    begin
        if I_areset = '1' then
            pc <= (others => '0');
            if HAVE_BOOTLOADER_ROM then
                pc(pc'left downto pc'left-3) <= BOOT_HIGH_NIBBLE;
            else
                pc(pc'left downto pc'left-3) <= ROM_HIGH_NIBBLE;
            end if;
        elsif rising_edge(I_clk) then
            -- Load DPC to PC
            if control.load_pc = '1' then
                pc <= csr_reg.dpc;
            -- Should we stall the pipeline
            elsif control.stall = '1' or control.stall_on_trigger = '1' then
                -- PC holds value
                null;
            else
                case id_ex.pc_op is
                    -- Hold the PC
                    when pc_hold =>
                        null;
                    -- Increment the PC
                    when pc_incr =>
                        pc <= std_logic_vector(unsigned(pc) + 4);
                    -- JAL
                    when pc_loadoffset =>
                        pc <= std_logic_vector(unsigned(id_ex.pc) + unsigned(id_ex.imm));
                    -- JALR
                    when pc_loadoffsetregister =>
                        -- Check forwarding
                        if control.forwarda = '1' then
                            pc <= std_logic_vector(unsigned(id_ex.imm) + unsigned(ex_wb.rddata));
                        else
                            pc <= std_logic_vector(unsigned(id_ex.imm) + unsigned(id_ex.rs1data));
                        end if;
                        -- As per RISC-V unpriv spec
                        pc(0) <= '0';
                    -- Branch
                    when pc_branch =>
                        -- Must we branch?
                        if control.penalty = '1' then
                            pc <= std_logic_vector(unsigned(id_ex.pc) + unsigned(id_ex.imm));
                        else
                            pc <= std_logic_vector(unsigned(pc) + 4);
                        end if;
                    -- Load mtvec, direct or vectored
                    when pc_load_mtvec =>
                        pc <= csr_transfer.mtvec_to_pc;
                    -- Load mepc
                    when pc_load_mepc =>
                        pc <= csr_transfer.mepc_to_pc;
                    when others =>
                        pc <= std_logic_vector(unsigned(pc) + 4);
                end case;
            end if;
            -- Lower two bits always 0
            --pc(1 downto 0) <= "00";
        end if;
    end process;
    -- For fetching instructions
    O_instr_request.pc <= pc;

    
    -- The PC at the fetched instruction
    process (I_clk, I_areset) is
    variable instr_var : data_type;
    begin
        if I_areset = '1' then
            -- Set at 0x00000000 because after reset
            -- the processor will run for two booting
            -- states. After that, this PC will follow
            -- the PC.
            if_id.pc <= (others => '0');
        elsif rising_edge(I_clk) then
            -- Must we stall?
            if control.stall = '1' or control.stall_on_trigger = '1' or id_ex.pc_op = pc_hold then
                null;
            else
                if_id.pc <= pc;
            end if;
        end if;
    end process;

    
    --
    -- Instruction decode block
    --
    --id_ex.instr <= I_instr_response.instr;
   
    process (I_clk, I_areset, I_instr_response, control) is
    variable opcode_v : std_logic_vector(6 downto 0);
    variable func3_v : std_logic_vector(2 downto 0);
    variable func7_v : std_logic_vector(6 downto 0);
    variable imm_u_v : data_type;
    variable imm_j_v : data_type;
    variable imm_i_v : data_type;
    variable imm_b_v : data_type;
    variable imm_s_v : data_type;
    variable imm_shamt_v : data_type;
    variable rs1_v, rs2_v, rd_v : reg_type;
    variable selrs1_v : integer range 0 to NUMBER_OF_REGISTERS-1;
    variable selrs2_v : integer range 0 to NUMBER_OF_REGISTERS-1;
    begin

        -- Replace opcode with a nop if we flush
        if control.flush = '1' then
            opcode_v := "0010011"; --nop
            rd_v := (others => '0');
        else
            -- Get the opcode
            opcode_v := I_instr_response.instr(6 downto 0);
            rd_v := I_instr_response.instr(11 downto 7);
        end if;

        -- Registers to select
        rs1_v := I_instr_response.instr(19 downto 15);
        rs2_v := I_instr_response.instr(24 downto 20);

        -- Get function (extends the opcode)
        func3_v := I_instr_response.instr(14 downto 12);
        func7_v := I_instr_response.instr(31 downto 25);

        -- Create all immediate formats
        imm_u_v(31 downto 12) := I_instr_response.instr(31 downto 12);
        imm_u_v(11 downto 0) := (others => '0');
        
        imm_j_v(31 downto 21) := (others => I_instr_response.instr(31));
        imm_j_v(20 downto 1) := I_instr_response.instr(31) & I_instr_response.instr(19 downto 12) & I_instr_response.instr(20) & I_instr_response.instr(30 downto 21);
        imm_j_v(0) := '0';

        imm_i_v(31 downto 12) := (others => I_instr_response.instr(31));
        imm_i_v(11 downto 0) := I_instr_response.instr(31 downto 20);
        
        imm_b_v(31 downto 13) := (others => I_instr_response.instr(31));
        imm_b_v(12 downto 1) := I_instr_response.instr(31) & I_instr_response.instr(7) & I_instr_response.instr(30 downto 25) & I_instr_response.instr(11 downto 8);
        imm_b_v(0) := '0';

        imm_s_v(31 downto 12) := (others => I_instr_response.instr(31));
        imm_s_v(11 downto 0) := I_instr_response.instr(31 downto 25) & I_instr_response.instr(11 downto 7);
        
        imm_shamt_v(31 downto 5) := (others => '0');
        imm_shamt_v(4 downto 0) := rs2_v;

        -- Select registers from the register file
        selrs1 <= to_integer(unsigned(rs1_v));
        selrs2 <= to_integer(unsigned(rs2_v));
        
        if I_areset = '1' then
            id_ex.pc <= (others => '0');
            id_ex.instr <= (others => 'X');
            id_ex.rd <= (others => '0');
            id_ex.rs1 <= (others => '0');
            id_ex.rs2 <= (others => '0');
            id_ex.rd_en <= '1';
            id_ex.imm <= (others => '0');
            id_ex.isimm <= '0';
            id_ex.isunsigned <= '0';
            id_ex.ismem <= '0';
            id_ex.alu_op <= alu_unknown;
            id_ex.pc_op <= pc_incr;
            id_ex.md_start <= '0';
            id_ex.md_op <= (others => '0');
            id_ex.memaccess <= memaccess_nop;
            id_ex.memsize <= memsize_unknown;
            id_ex.csr_op <= csr_nop;
            id_ex.csr_addr <= (others => '0');
            id_ex.csr_immrs1 <= (others => '0');
            control.ecall_request <= '0';
            control.ebreak_request <= '0';
            control.mret_request <= '0';
            control.wfi_request <= '0';
            control.illegal_instruction_decode <= '0';
            control.reg0_write_once <= '0';
        elsif rising_edge(I_clk) then
            id_ex.instr <= I_instr_response.instr;
            if control.stall_on_trigger = '1' then
                -- Set all registers to default
                id_ex.rd <= (others => '0');
                id_ex.rs1 <= (others => '0');
                id_ex.rs2 <= (others => '0');
                id_ex.rd_en <= '0';
                id_ex.imm <= imm_i_v;
                id_ex.isimm <= '0';
                id_ex.isunsigned <= '0';
                id_ex.ismem <= '0';
                id_ex.alu_op <= alu_nop;
                id_ex.pc_op <= pc_incr;
                id_ex.md_start <= '0';
                id_ex.md_op <= (others => '0');
                id_ex.memaccess <= memaccess_nop;
                id_ex.memsize <= memsize_unknown;
                id_ex.csr_op <= csr_nop;
                id_ex.csr_addr <= (others => '0');
                id_ex.csr_immrs1 <= (others => '0');
                control.ecall_request <= '0';
                control.ebreak_request <= '0';
                control.mret_request <= '0';
                control.wfi_request <= '0';
                control.illegal_instruction_decode <= '0';
            -- if a trap is requested
            elsif control.trap_request = '1' then
                -- ALU does nothing
                id_ex.alu_op <= alu_nop;
                -- No writeback to register
                id_ex.rd <= (others => '0');
                id_ex.rd_en <= '0';
                -- Load PC with MTVEC CSR
                id_ex.pc_op <= pc_load_mtvec;
                -- Disable CSR operation
                id_ex.csr_op <= csr_nop;
                -- Do not start the MD unit
                id_ex.md_start <= '0';
                -- ECALL request reset
                control.ecall_request <= '0';
                -- EBREAK request reset
                control.ebreak_request <= '0';
                control.wfi_request <= '0';
                -- Illegal instruction reset
                control.illegal_instruction_decode <= '0';
--                control.reg0_write_once <= '1';
            -- We need to stall the operation
            elsif control.stall = '1' then
                -- Set id_ex.md_start to 0. It is already registered.
                id_ex.md_start <= '0';
                -- If the MD unit is ready and we are still doing MD operation,
                -- load the data in the selected register. MD operation cannot
                -- be interrupted by trap.
                if md.ready = '1' then
                    id_ex.pc_op <= pc_incr;
                    id_ex.rd_en <= '1';
                end if;
                control.wfi_request <= '0';
            else
                -- Set all registers to default
                id_ex.pc <= if_id.pc;
                id_ex.rd <= rd_v;
                id_ex.rs1 <= rs1_v;
                id_ex.rs2 <= rs2_v;
                id_ex.rd_en <= '0';
                id_ex.imm <= imm_i_v;
                id_ex.isimm <= '0';
                id_ex.isunsigned <= '0';
                id_ex.ismem <= '0';
                id_ex.alu_op <= alu_nop;
                id_ex.pc_op <= pc_incr;
                id_ex.md_start <= '0';
                id_ex.md_op <= (others => '0');
                id_ex.memaccess <= memaccess_nop;
                id_ex.memsize <= memsize_unknown;
                id_ex.csr_op <= csr_nop;
                id_ex.csr_addr <= (others => '0');
                id_ex.csr_immrs1 <= (others => '0');
                control.ecall_request <= '0';
                control.ebreak_request <= '0';
                control.mret_request <= '0';
                control.wfi_request <= '0';
                control.illegal_instruction_decode <= '0';
                control.reg0_write_once <= '1';

                if control.flush = '1' or control.state = state_debugflush or control.state = state_debugflush2 then
                    id_ex.alu_op <= alu_nop;
                else
                    case opcode_v is
                        -- LUI
                        when "0110111" =>
                            id_ex.alu_op <= alu_lui;
                            id_ex.rd_en <= '1';
                            id_ex.imm <= imm_u_v;
                            id_ex.isimm <= '1';
                        -- AUIPC
                        when "0010111" =>
                            id_ex.alu_op <= alu_auipc;
                            id_ex.rd_en <= '1';
                            id_ex.imm <= imm_u_v;
                            id_ex.isimm <= '1';
                        -- JAL
                        when "1101111" =>
                            id_ex.alu_op <= alu_jal_jalr;
                            id_ex.pc_op <= pc_loadoffset;
                            id_ex.rd_en <= '1';
                            id_ex.imm <= imm_j_v;
                        -- JALR
                        when "1100111" =>
                            if func3_v = "000" then
                                id_ex.alu_op <= alu_jal_jalr;
                                id_ex.pc_op <= pc_loadoffsetregister;
                                id_ex.rd_en <= '1';
                                id_ex.imm <= imm_i_v;
                            else
                                control.illegal_instruction_decode <= '1';
                            end if;
                        -- Branches
                        when "1100011" =>
                            -- Set the registers to compare. Comparison is handled by the ALU.
                            id_ex.imm <= imm_b_v;
                            id_ex.pc_op <= pc_branch;
                            case func3_v is
                                when "000" => id_ex.alu_op <= alu_beq;
                                when "001" => id_ex.alu_op <= alu_bne;
                                when "100" => id_ex.alu_op <= alu_blt;
                                when "101" => id_ex.alu_op <= alu_bge;
                                when "110" => id_ex.alu_op <= alu_bltu; id_ex.isunsigned <= '1';
                                when "111" => id_ex.alu_op <= alu_bgeu; id_ex.isunsigned <= '1';
                                when others =>
                                    -- Reset defaults
                                    id_ex.pc_op <= pc_incr;
                                    control.illegal_instruction_decode <= '1';
                            end case;

                        -- Arithmetic/logic register/immediate
                        when "0010011" =>
                            -- ADDI
                            if func3_v = "000" then
                                id_ex.alu_op <= alu_addi;
                                id_ex.rd_en <= '1';
                                id_ex.imm <= imm_i_v;
                                id_ex.isimm <= '1';
                            -- SLTI
                            elsif func3_v = "010" then
                                id_ex.alu_op <= alu_slti;
                                id_ex.rd_en <= '1';
                                id_ex.imm <= imm_i_v;
                                id_ex.isimm <= '1';
                            -- SLTIU
                            elsif func3_v = "011" then
                                id_ex.alu_op <= alu_sltiu;
                                id_ex.rd_en <= '1';
                                id_ex.imm <= imm_i_v;
                                id_ex.isimm <= '1';
                                id_ex.isunsigned <= '1';
                            -- XORI
                            elsif func3_v = "100" then
                                id_ex.alu_op <= alu_xori;
                                id_ex.rd_en <= '1';
                                id_ex.imm <= imm_i_v;
                                id_ex.isimm <= '1';
                            -- ORI
                            elsif func3_v = "110" then
                                id_ex.alu_op <= alu_ori;
                                id_ex.rd_en <= '1';
                                id_ex.imm <= imm_i_v;
                                id_ex.isimm <= '1';
                            -- ANDI
                            elsif func3_v = "111" then
                                id_ex.alu_op <= alu_andi;
                                id_ex.rd_en <= '1';
                                id_ex.imm <= imm_i_v;
                                id_ex.isimm <= '1';
                            -- SLLI
                            elsif func3_v = "001" and func7_v = "0000000" then
                                id_ex.alu_op <= alu_slli;
                                id_ex.rd_en <= '1';
                                id_ex.imm <= imm_shamt_v;
                                id_ex.isimm <= '1';
                            -- SRLI
                            elsif func3_v = "101" and func7_v = "0000000" then
                                id_ex.alu_op <= alu_srli;
                                id_ex.rd_en <= '1';
                                id_ex.imm <= imm_shamt_v;
                                id_ex.isimm <= '1';
                            -- SRAI
                            elsif func3_v = "101" and func7_v = "0100000" then
                                id_ex.alu_op <= alu_srai;
                                id_ex.rd_en <= '1';
                                id_ex.imm <= imm_shamt_v;
                                id_ex.isimm <= '1';
                            -- BCLRI
                            elsif func3_v = "001" and func7_v = "0100100" and HAVE_ZBS then
                                id_ex.alu_op <= alu_bclri;
                                id_ex.rd_en <= '1';
                                id_ex.imm <= imm_shamt_v;
                                id_ex.isimm <= '1';
                            -- BEXTI
                            elsif func3_v = "101" and func7_v = "0100100" and HAVE_ZBS then
                                id_ex.alu_op <= alu_bexti;
                                id_ex.rd_en <= '1';
                                id_ex.imm <= imm_shamt_v;
                                id_ex.isimm <= '1';
                            -- BINVI
                            elsif func3_v = "001" and func7_v = "0110100" and HAVE_ZBS then
                                id_ex.alu_op <= alu_binvi;
                                id_ex.rd_en <= '1';
                                id_ex.imm <= imm_shamt_v;
                                id_ex.isimm <= '1';
                             -- BSETI
                             elsif func3_v = "001" and func7_v = "0010100" and HAVE_ZBS then
                                id_ex.alu_op <= alu_bseti;
                                id_ex.rd_en <= '1';
                                id_ex.imm <= imm_shamt_v;
                                id_ex.isimm <= '1';
                            else
                                control.illegal_instruction_decode <= '1';
                            end if;

                        -- Arithmetic/logic register/register
                        when "0110011" =>
                            -- ADD
                            if func3_v = "000" and func7_v = "0000000" then
                                id_ex.alu_op <= alu_add;
                                id_ex.rd_en <= '1';
                            -- SUB
                            elsif func3_v = "000" and func7_v = "0100000" then
                                id_ex.alu_op <= alu_sub;
                                id_ex.rd_en <= '1';
                            -- SLL
                            elsif func3_v = "001" and func7_v = "0000000" then
                                id_ex.alu_op <= alu_sll; 
                                id_ex.rd_en <= '1';
                            -- SLT
                            elsif func3_v = "010" and func7_v = "0000000" then
                                id_ex.alu_op <= alu_slt; 
                                id_ex.rd_en <= '1';
                            -- SLTU
                            elsif func3_v = "011" and func7_v = "0000000" then
                                id_ex.alu_op <= alu_sltu; 
                                id_ex.rd_en <= '1';
                                id_ex.isunsigned <= '1';
                            -- XOR
                            elsif func3_v = "100" and func7_v = "0000000" then
                                id_ex.alu_op <= alu_xor; 
                                id_ex.rd_en <= '1';
                            -- SRL
                            elsif func3_v = "101" and func7_v = "0000000" then
                                id_ex.alu_op <= alu_srl; 
                                id_ex.rd_en <= '1';
                            -- SRA
                            elsif func3_v = "101" and func7_v = "0100000" then
                                id_ex.alu_op <= alu_sra; 
                                id_ex.rd_en <= '1';
                            -- OR
                            elsif func3_v = "110" and func7_v = "0000000" then
                                id_ex.alu_op <= alu_or;
                                id_ex.rd_en <= '1';
                            -- AND
                            elsif func3_v = "111" and func7_v = "0000000" then
                                id_ex.alu_op <= alu_and;
                                id_ex.rd_en <= '1';
                            -- SH1ADD
                            elsif func3_v = "010" and func7_v = "0010000" and HAVE_ZBA then
                                id_ex.alu_op <= alu_sh1add;
                                id_ex.rd_en <= '1';
                            -- SH2ADD
                            elsif func3_v = "100" and func7_v = "0010000" and HAVE_ZBA then
                                id_ex.alu_op <= alu_sh2add;
                                id_ex.rd_en <= '1';
                            -- SH3ADD
                            elsif func3_v = "110" and func7_v = "0010000" and HAVE_ZBA then
                                id_ex.alu_op <= alu_sh3add;
                                id_ex.rd_en <= '1';
                            -- BCLR
                            elsif func3_v = "001" and func7_v = "0100100" and HAVE_ZBS then
                                id_ex.alu_op <= alu_bclr;
                                id_ex.rd_en <= '1';
                            -- BEXT
                            elsif func3_v = "101" and func7_v = "0100100" and HAVE_ZBS then
                                id_ex.alu_op <= alu_bext;
                                id_ex.rd_en <= '1';
                            -- BINV
                            elsif func3_v = "001" and func7_v = "0110100" and HAVE_ZBS then
                                id_ex.alu_op <= alu_binv;
                                id_ex.rd_en <= '1';
                            -- BSET
                            elsif func3_v = "001" and func7_v = "0010100" and HAVE_ZBS then
                                id_ex.alu_op <= alu_bset;
                                id_ex.rd_en <= '1';
                            -- CZERO.EQZ
                            elsif func3_v = "101" and func7_v = "0000111" and HAVE_ZICOND then
                                id_ex.alu_op <= alu_czeroeqz;
                                id_ex.rd_en <= '1';
                            -- CZERO.NEZ
                            elsif func3_v = "111" and func7_v = "0000111" and HAVE_ZICOND then
                                id_ex.alu_op <= alu_czeronez;
                                id_ex.rd_en <= '1';
                            -- Multiply, divide, remainder
                            elsif func7_v = "0000001" then
                                -- Set operation to multiply or divide/remainder
                                -- func3 contains the real operation
                                if HAVE_MULDIV then
                                    case func3_v(2) is
                                        when '0' => id_ex.alu_op <= alu_multiply;
                                        when '1' => id_ex.alu_op <= alu_divrem;
                                        when others => null;
                                    end case;
                                    -- Hold the PC
                                    id_ex.pc_op <= pc_hold;
                                    -- func3 contains the function
                                    id_ex.md_op <= func3_v;
                                    -- Start multiply/divide/remainder
                                    id_ex.md_start <= '1';
                                else
                                    control.illegal_instruction_decode <= '1';
                                end if;
                            else
                                control.illegal_instruction_decode <= '1';
                            end if;

                        -- S(W|H|B)
                        when "0100011" =>
                            case func3_v is
                                -- Store byte (no sign extension or zero extension)
                                when "000" =>
                                    id_ex.alu_op <= alu_sb;
                                    id_ex.memaccess <= memaccess_write;
                                    id_ex.memsize <= memsize_byte;
                                    id_ex.imm <= imm_s_v;
                                    id_ex.ismem <= boolean_to_std_logic(not HAVE_FAST_STORE);
                                -- Store halfword (no sign extension or zero extension)
                                when "001" =>
                                    id_ex.alu_op <= alu_sh;
                                    id_ex.memaccess <= memaccess_write;
                                    id_ex.memsize <= memsize_halfword;
                                    id_ex.imm <= imm_s_v;
                                    id_ex.ismem <= boolean_to_std_logic(not HAVE_FAST_STORE);
                                    -- Store word (no sign extension or zero extension)
                                when "010" =>
                                    id_ex.alu_op <= alu_sw;
                                    id_ex.memaccess <= memaccess_write;
                                    id_ex.memsize <= memsize_word;
                                    id_ex.imm <= imm_s_v;
                                    id_ex.ismem <= boolean_to_std_logic(not HAVE_FAST_STORE);
                                when others =>
                                    control.illegal_instruction_decode <= '1';
                            end case;
                            
                        -- L{W|H|B|HU|BU}
                        -- Data from memory is routed through the ALU
                        when "0000011" =>
                            case func3_v is
                                -- LB
                                when "000" =>
                                    id_ex.alu_op <= alu_lb;
                                    id_ex.rd_en <= '1';
                                    id_ex.memaccess <= memaccess_read;
                                    id_ex.memsize <= memsize_byte;
                                    id_ex.imm <= imm_i_v;
                                    id_ex.ismem <= '1';
                                -- LH
                                when "001" =>
                                    id_ex.alu_op <= alu_lh;
                                    id_ex.rd_en <= '1';
                                    id_ex.memaccess <= memaccess_read;
                                    id_ex.memsize <= memsize_halfword;
                                    id_ex.imm <= imm_i_v;
                                    id_ex.ismem <= '1';
                                -- LW
                                when "010" =>
                                    id_ex.alu_op <= alu_lw;
                                    id_ex.rd_en <= '1';
                                    id_ex.memaccess <= memaccess_read;
                                    id_ex.memsize <= memsize_word;
                                    id_ex.imm <= imm_i_v;
                                    id_ex.ismem <= '1';
                                -- LBU
                                when "100" =>
                                    id_ex.alu_op <= alu_lbu;
                                    id_ex.rd_en <= '1';
                                    id_ex.memaccess <= memaccess_read;
                                    id_ex.memsize <= memsize_byte;
                                    id_ex.imm <= imm_i_v;
                                    id_ex.ismem <= '1';
                                -- LHU
                                when "101" =>
                                    id_ex.alu_op <= alu_lhu;
                                    id_ex.rd_en <= '1';
                                    id_ex.memaccess <= memaccess_read;
                                    id_ex.memsize <= memsize_halfword;
                                    id_ex.imm <= imm_i_v;
                                    id_ex.ismem <= '1';
                                when others =>
                                    control.illegal_instruction_decode <= '1';
                            end case;

                        -- CSR{}, {ECALL, EBREAK, MRET, WFI}
                        when "1110011" =>
                            case func3_v is
                                when "000" =>
                                    -- ECALL/EBREAK/MRET/WFI
                                    if I_instr_response.instr(31 downto 20) = "000000000000" then
                                        -- ECALL
                                        control.ecall_request <= '1';
                                        id_ex.alu_op <= alu_trap;
                                        id_ex.pc_op <= pc_hold;
                                    elsif I_instr_response.instr(31 downto 20) = "000000000001" then
                                        -- EBREAK
                                        control.ebreak_request <= '1';
                                        -- Check the dcsr.ebreakm flag, if 0 then trap
                                        if csr_reg.dcsr(15) = '0' then
                                            id_ex.alu_op <= alu_trap;
                                            id_ex.pc_op <= pc_hold;
                                        end if;
                                    elsif I_instr_response.instr(31 downto 20) = "001100000010" then
                                        -- MRET
                                        id_ex.alu_op <= alu_mret;
                                        control.mret_request <= '1';
                                        id_ex.pc_op <= pc_load_mepc;
                                    elsif I_instr_response.instr(31 downto 20) = "000100000101" then
                                        -- WFI
                                        -- Only execute while not stepping
                                        control.wfi_request <= not control.isstepping;
                                        null;
                                    else
                                        control.illegal_instruction_decode <= '1';
                                    end if;
                                when "001" =>
                                    id_ex.alu_op <= alu_csr;
                                    id_ex.csr_op <= csr_rw;
                                    id_ex.rd_en <= '1';
                                    id_ex.csr_addr <= imm_i_v(11 downto 0);
                                    id_ex.csr_immrs1 <= rs1_v; -- RS1
                                when "010" =>
                                    id_ex.alu_op <= alu_csr;
                                    id_ex.csr_op <= csr_rs;
                                    id_ex.rd_en <= '1';
                                    id_ex.csr_addr <= imm_i_v(11 downto 0);
                                    id_ex.csr_immrs1 <= rs1_v; -- RS1
                                when "011" =>
                                    id_ex.alu_op <= alu_csr;
                                    id_ex.csr_op <= csr_rc;
                                    id_ex.rd_en <= '1';
                                    id_ex.csr_addr <= imm_i_v(11 downto 0);
                                    id_ex.csr_immrs1 <= rs1_v; -- RS1
                                when "101" =>
                                    id_ex.alu_op <= alu_csr;
                                    id_ex.csr_op <= csr_rwi;
                                    id_ex.rd_en <= '1';
                                    id_ex.csr_addr <= imm_i_v(11 downto 0);
                                    id_ex.csr_immrs1 <= rs1_v; -- imm
                                when "110" =>
                                    id_ex.alu_op <= alu_csr;
                                    id_ex.csr_op <= csr_rsi;
                                    id_ex.rd_en <= '1';
                                    id_ex.csr_addr <= imm_i_v(11 downto 0);
                                    id_ex.csr_immrs1 <= rs1_v; -- imm
                                when "111" =>
                                    id_ex.alu_op <= alu_csr;
                                    id_ex.csr_op <= csr_rci;
                                    id_ex.rd_en <= '1';
                                    id_ex.csr_addr <= imm_i_v(11 downto 0);
                                    id_ex.csr_immrs1 <= rs1_v; -- imm
                                when others =>
                                    control.illegal_instruction_decode <= '1';
                            end case;

                        -- FENCE, FENCE.I
                        when "0001111" =>
                            if func3_v = "000" or func3_v = "001" then
                                -- Just ignore
                                null;
                            else
                                control.illegal_instruction_decode <= '1';
                            end if;
                            
                        -- Illegal instruction or not implemented
                        when others =>
                            control.illegal_instruction_decode <= '1';
                    end case;
                    
                    -- When the registers use onboard RAM, the registers
                    -- cannot be reset. In that case, we must write register
                    -- x0 (zero) with 0x00000000. This needs to be done only
                    -- once when the processor starts up. After that, register
                    -- x0 is not written anymore. When the processor starts,
                    -- it executes an `alu_nop`, which sets the result to 0 so
                    -- register x0 is written with 0x00000000.
                    if control.reg0_write_once = '0' and HAVE_REGISTERS_IN_RAM then
                        id_ex.rd_en <= '1';
                    elsif rd_v = "00000" then
                        id_ex.rd_en <= '0';
                    end if;
               end if; -- flush
            end if; -- stall
        end if; -- rising_edge
            
    end process;

    
    --
    -- The registers.
    -- Due to the nature of the registers, three separate processes are used:
    -- One for first source register, one for second source register and one
    -- for debugging purposes. Most synthesizers will create registers in
    -- onboard RAM blocks.
    --
    
    -- Generate register in onboard RAM blocks
    gen_regs_ram: if HAVE_REGISTERS_IN_RAM generate
        -- Registers: retire
        -- Do NOT include a reset, otherwise registers will be in ALM flip-flops
        -- Do NOT set x0 to all zero bits
        -- Next process is for the core register RS1
        process (I_clk, I_areset, control, id_ex, I_dm_core_data_request) is
        variable selrd_v : integer range 0 to NUMBER_OF_REGISTERS-1;
        begin
            if control.indebug = '1' then
                selrd_v := to_integer(unsigned(I_dm_core_data_request.address(4 downto 0)));
            else
                selrd_v := to_integer(unsigned(id_ex.rd));
            end if;
            if rising_edge(I_clk) then
                if control.indebug = '0' and control.stall = '0' and control.stall_on_trigger = '0' and id_ex.rd_en = '1' and control.trap_request = '0' then
                    regs_rs1(selrd_v) <= id_ex.result;
                elsif control.indebug = '1' and I_dm_core_data_request.writegpr = '1' then
                    regs_rs1(selrd_v) <= I_dm_core_data_request.data;
                end if;
                if control.stall_on_trigger = '1' or control.stall = '1' or control.trap_request = '1' then
                else
                    id_ex.rs1data <= regs_rs1(selrs1);
                end if;
            end if;
        end process;
        -- Next process is for the core register RS2
        process (I_clk, I_areset, control, id_ex, I_dm_core_data_request) is
        variable selrd_v : integer range 0 to NUMBER_OF_REGISTERS-1;
        begin
            if control.indebug = '1' then
                selrd_v := to_integer(unsigned(I_dm_core_data_request.address(4 downto 0)));
            else
                selrd_v := to_integer(unsigned(id_ex.rd));
            end if;
            if rising_edge(I_clk) then
                if control.indebug = '0' and control.stall = '0' and control.stall_on_trigger = '0' and id_ex.rd_en = '1' and control.trap_request = '0' then
                    regs_rs2(selrd_v) <= id_ex.result;
                elsif control.indebug = '1' and I_dm_core_data_request.writegpr = '1' then
                    regs_rs2(selrd_v) <= I_dm_core_data_request.data;
                end if;
                if control.stall_on_trigger = '1' or control.stall = '1' or control.trap_request = '1' then
                else
                    id_ex.rs2data <= regs_rs2(selrs2);
                end if;
            end if;
        end process;
        -- Next process is for the debug read.
        -- We can't use RS1 or RS2, because RAM blocks can have only one output.
        process (I_clk, I_areset, control, id_ex, I_dm_core_data_request) is
        variable selrd_v : integer range 0 to NUMBER_OF_REGISTERS-1;
        begin
            if control.indebug = '1' then
                selrd_v := to_integer(unsigned(I_dm_core_data_request.address(4 downto 0)));
            else
                selrd_v := to_integer(unsigned(id_ex.rd));
            end if;
            if rising_edge(I_clk) then
                if control.indebug = '0' and control.stall = '0' and control.stall_on_trigger = '0' and id_ex.rd_en = '1' and control.trap_request = '0' then
                    regs_debug(selrd_v) <= id_ex.result;
                elsif control.indebug = '1' and I_dm_core_data_request.writegpr = '1' then
                    regs_debug(selrd_v) <= I_dm_core_data_request.data;
                end if;
                data_from_gpr <= regs_debug(selrd_v);
            end if;
        end process;
    end generate;

    -- Generate registers in ALM flip-flops
    gen_regs_ram_not: if not HAVE_REGISTERS_IN_RAM generate
        -- Register: exec & retire
        -- Registers in ALM flip-flops, x0 (zero) hardwired to all 0.
        -- Registers are cleared on reset
        process (I_clk, I_areset, id_ex.rd, I_instr_response.instr, I_dm_core_data_request.address) is
        variable selrd_v : integer range 0 to NUMBER_OF_REGISTERS-1;
        begin
            if control.indebug = '1' then
                selrd_v := to_integer(unsigned(I_dm_core_data_request.address(4 downto 0)));
            else
                selrd_v := to_integer(unsigned(id_ex.rd));
            end if;

            if I_areset = '1' then
                regs_debug <= (others => (others => '0'));
                id_ex.rs1data <= (others => '0');
                id_ex.rs2data <= (others => '0');
            elsif rising_edge(I_clk) then
                if control.indebug = '0' and control.stall = '0' and control.stall_on_trigger = '0' and id_ex.rd_en = '1' and control.trap_request = '0' then
                    regs_debug(selrd_v) <= id_ex.result;
                elsif control.indebug = '1' and I_dm_core_data_request.writegpr = '1' then
                    regs_debug(selrd_v) <= I_dm_core_data_request.data;
                end if;
                regs_debug(0) <= (others => '0');
                if control.stall_on_trigger = '1' or control.stall = '1' or control.trap_request = '1' then
                    null;
                else
                    id_ex.rs1data <= regs_debug(selrs1);
                    id_ex.rs2data <= regs_debug(selrs2);
                end if;
                data_from_gpr <= regs_debug(selrd_v);
            end if;
        end process;
    end generate;

    
    --
    -- The execute block
    -- Contains the ALU, the MD unit and result retire unit
    --
    
    -- ALU
    process (id_ex, control, ex_wb, md, csr_access, I_bus_response.data) is
    variable a_v, b_v, r_v, imm_v : data_type;
    variable al_v, bl_v : std_logic_vector(data_type'left+1 downto 0);
    variable signs_v : data_type;
    variable cmpeq_v, cmplt_v : std_logic;
    variable bitsft_v : data_type;
    begin
    
        -- Check if forwarding result is needed
        if control.forwarda = '1' then
            a_v := ex_wb.rddata;
        else
            a_v := id_ex.rs1data;
        end if;
            
        -- Check if immediate or forwarding result is needed
        if id_ex.isimm = '1' then
            b_v := id_ex.imm;
        elsif control.forwardb = '1' then
            b_v := ex_wb.rddata;
        else
            b_v := id_ex.rs2data;
        end if;
        
        -- Create a zero or signed extended version of the operands.
        -- For signed operations, the operands are sign extended and
        -- will compare as normal signed operands. For unsigned
        -- operation (SLTU, SLTIU, BLTU and BGEU), the operands are
        -- zero extended and will compare as unsigned operands even
        -- though the compare is signed.
        al_v := (a_v(a_v'left) and (not id_ex.isunsigned)) & a_v;
        bl_v := (b_v(b_v'left) and (not id_ex.isunsigned)) & b_v;
        
        -- Compare equal
        if a_v = b_v then
            cmpeq_v := '1';
        else
            cmpeq_v := '0';
        end if;
        -- Compare less-than
        if signed(al_v) < signed(bl_v) then
            cmplt_v := '1';
        else
            cmplt_v := '0';
        end if;
        
        r_v := (others => '0');
        
        control.penalty <= '0';
        
        case id_ex.alu_op is
            -- No operation
            when alu_nop | alu_unknown | alu_sw | alu_sh | alu_sb | alu_trap =>
                null;

            -- Return from trap
            when alu_mret =>
                control.penalty <= '1';
                
            -- Simple arithmetic and logic
            when alu_add | alu_addi | alu_sh1add | alu_sh2add | alu_sh3add =>
                if HAVE_ZBA then
                    if id_ex.alu_op = alu_sh1add then
                        a_v := a_v(a_v'left-1 downto 0) & '0';
                    elsif id_ex.alu_op = alu_sh2add then
                        a_v := a_v(a_v'left-2 downto 0) & "00";
                    elsif id_ex.alu_op = alu_sh3add then
                        a_v := a_v(a_v'left-3 downto 0) & "000";
                    end if;
                end if;
                r_v := std_logic_vector(unsigned(a_v) + unsigned(b_v));
            when alu_sub =>
                r_v := std_logic_vector(unsigned(a_v) - unsigned(b_v));
            when alu_and | alu_andi =>
                r_v := a_v and b_v;
            when alu_or | alu_ori =>
                r_v := a_v or b_v;
            when alu_xor | alu_xori =>
                r_v := a_v xor b_v;
            when alu_czeroeqz =>
                if HAVE_ZICOND then
                    if b_v = all_zeros_c then
                        r_v := all_zeros_c;
                    else
                        r_v := a_v;
                    end if;
                end if;
            when alu_czeronez =>
                if HAVE_ZICOND then
                    if b_v /= all_zeros_c then
                        r_v := all_zeros_c;
                    else
                        r_v := a_v;
                    end if;
                end if;
            when alu_bclr | alu_bclri =>
                if HAVE_ZBS then
                    bitsft_v := (others => '0');
                    bitsft_v(to_integer(unsigned(b_v(4 downto 0)))) := '1';
                    r_v := a_v and not bitsft_v;
                 end if;
            when alu_binv | alu_binvi =>
                if HAVE_ZBS then
                    bitsft_v := (others => '0');
                    bitsft_v(to_integer(unsigned(b_v(4 downto 0)))) := '1';
                    r_v := a_v xor bitsft_v;
                 end if;
            when alu_bset | alu_bseti =>
                if HAVE_ZBS then
                    bitsft_v := (others => '0');
                    bitsft_v(to_integer(unsigned(b_v(4 downto 0)))) := '1';
                    r_v := a_v or bitsft_v;
                 end if;
            when alu_bext | alu_bexti =>
                if HAVE_ZBS then
                    if a_v(to_integer(unsigned(b_v(4 downto 0)))) = '1' then
                        r_v(0) := '1';
                    end if;
                 end if;
                 
            -- Test register & immediate signed/unsigned
            when alu_slt | alu_slti |alu_sltu | alu_sltiu =>
                r_v(0) := cmplt_v;

            -- Shifts et al
            when alu_sll | alu_slli =>
                if b_v(4) = '1' then
                    a_v := a_v(a_v'left-16 downto 0) & all_zeros_c(15 downto 0);
                end if;
                if b_v(3) = '1' then
                    a_v := a_v(a_v'left-8 downto 0) & all_zeros_c(7 downto 0);
                end if;
                if b_v(2) = '1' then
                    a_v := a_v(a_v'left-4 downto 0) & all_zeros_c(3 downto 0);
                end if;
                if b_v(1) = '1' then
                    a_v := a_v(a_v'left-2 downto 0) & all_zeros_c(1 downto 0);
                end if;
                if b_v(0) = '1' then
                    a_v := a_v(a_v'left-1 downto 0) & all_zeros_c(0 downto 0);
                end if;
                r_v := a_v;

            when alu_sra | alu_srai | alu_srl | alu_srli =>
                if id_ex.alu_op = alu_srl or id_ex.alu_op = alu_srli then
                    signs_v := all_zeros_c;
                else
                    signs_v := (others => a_v(a_v'left));
                end if;
                if b_v(4) = '1' then
                    a_v := signs_v(15 downto 0) & a_v(a_v'left downto 16);
                end if;
                if b_v(3) = '1' then
                    a_v := signs_v(7 downto 0) & a_v(a_v'left downto 8);
                end if;
                if b_v(2) = '1' then
                    a_v := signs_v(3 downto 0) & a_v(a_v'left downto 4);
                end if;
                if b_v(1) = '1' then
                    a_v := signs_v(1 downto 0) & a_v(a_v'left downto 2);
                end if;
                if b_v(0) = '1' then
                    a_v := signs_v(0 downto 0) & a_v(a_v'left downto 1);
                end if;
                r_v := a_v;
                
            -- Loads etc
            when alu_lui =>
                r_v := b_v;
            when alu_auipc =>
                r_v := std_logic_vector(unsigned(id_ex.pc) + unsigned(b_v)) ;
            when alu_lw =>
                r_v := I_bus_response.data;
            when alu_lh =>
                r_v := (others => I_bus_response.data(15));
                r_v(15 downto 0) := I_bus_response.data(15 downto 0);
            when alu_lhu =>
                r_v := (others => '0');
                r_v(15 downto 0) := I_bus_response.data(15 downto 0);
            when alu_lb =>
                r_v := (others => I_bus_response.data(7));
                r_v(7 downto 0) := I_bus_response.data(7 downto 0);
            when alu_lbu =>
                r_v := (others => '0');
                r_v(7 downto 0) := I_bus_response.data(7 downto 0);
                
            -- Jumps and calls
            when alu_jal_jalr =>
                r_v := std_logic_vector(unsigned(id_ex.pc) + 4);
                control.penalty <= '1';
                
            -- Branches
            when alu_beq =>
                r_v := (others => '0');
                r_v(0) := cmpeq_v;
                control.penalty <= cmpeq_v;
            when alu_bne =>
                r_v := (others => '0');
                r_v(0) := not cmpeq_v;
                control.penalty <= not cmpeq_v;
            when alu_blt | alu_bltu =>
                r_v := (others => '0');
                r_v(0) := cmplt_v;
                control.penalty <= cmplt_v;
            when alu_bge | alu_bgeu =>
                r_v := (others => '0');
                r_v(0) := not cmplt_v;
                control.penalty <= not cmplt_v;
                
            -- Pass data from CSR
            when alu_csr =>
                r_v := csr_access.datain;
                
            -- Pass data from multiplier
            when alu_multiply =>
                r_v := md.mul;
                
            -- Pass data from divider
            when alu_divrem =>
                r_v := md.div;
                
            --when others =>
            --    r := (others => '0');
        end case;
        
        -- The result is not clocked.
        id_ex.result <= r_v;
    end process;

    -- The MD unit, can be omitted by setting HAVE_MULDIV to false
    muldivgen: if HAVE_MULDIV generate
        -- Multiplication Unit
        -- Check start of multiplication and load registers
        process (I_clk, I_areset, control, ex_wb, id_ex) is
        variable a_v, b_v : data_type;
        begin
            -- Check if forwarding result is needed
            if control.forwarda = '1' then
                a_v := (ex_wb.rddata);
            else
                a_v := (id_ex.rs1data);
            end if;
                
            if control.forwardb = '1' then
                b_v := (ex_wb.rddata);
            else
                b_v := (id_ex.rs2data);
            end if;
        
            if I_areset = '1' then
                md.rdata_a <= (others => '0');
                md.rdata_b <= (others => '0');
                md.mul_running <= '0';
            elsif rising_edge(I_clk) then
                -- Clock in the multiplicand and multiplier
                -- In the Cyclone V, these are embedded registers
                -- in the DSP units.
                if id_ex.md_start = '1' and control.trap_request = '0' and control.stall_on_trigger = '0' then
                    if id_ex.md_op(1) = '1' then
                        if id_ex.md_op(0) = '1' then
                            md.rdata_a <= '0' & unsigned(a_v);
                        else
                            md.rdata_a <= a_v(31) & unsigned(a_v);
                        end if;
                        md.rdata_b <= '0' & unsigned(b_v);
                    else
                        md.rdata_a <= a_v(31) & unsigned(a_v);
                        md.rdata_b <= b_v(31) & unsigned(b_v);
                    end if;
                end if;
                -- Only start when start seen and multiply
                md.mul_running <= id_ex.md_start and not control.trap_request and not id_ex.md_op(2);
            end if;
        end process;

        -- Do the multiplication
        process(I_clk, I_areset) is
        begin
            if I_areset = '1' then
                md.mul_rd_int <= (others => '0');
                md.mul_ready <= '0';
            elsif rising_edge (I_clk) then
                -- Do the multiplication and store in embedded registers
                md.mul_rd_int <= signed(md.rdata_a) * signed(md.rdata_b);
                md.mul_ready <= md.mul_running;
            end if;
        end process;
        
        -- Output multiplier result
        process (md, id_ex) is
        begin
            if id_ex.md_op(1) = '1' or id_ex.md_op(0) = '1' then
                md.mul <= std_logic_vector(md.mul_rd_int(63 downto 32));
            else
                md.mul <= std_logic_vector(md.mul_rd_int(31 downto 0));
            end if;
        end process;

        fast_div: if FAST_DIVIDE generate
        -- The main divider process. The divider retires 2 bits
        -- at a time, hence 16 cycles are needed. We use a
        -- poor man's radix-4 subtraction unit. It is not the
        -- fastest hardware but the easiest to follow. Consider
        -- a SRT radix-4 divider.
        process (I_clk, I_areset, control, ex_wb, id_ex) is
        variable a_v, b_v : data_type;
        variable div_running_v : std_logic;  
        variable count_v : integer range 0 to 16;
        begin 
            -- Check if forwarding result is needed
            if control.forwarda = '1' then
                a_v := (ex_wb.rddata);
            else
                a_v := (id_ex.rs1data);
            end if;

            if control.forwardb = '1' then
                b_v := (ex_wb.rddata);
            else
                b_v := (id_ex.rs2data);
            end if;

            if I_areset = '1' then
                -- Reset everything
                count_v := 0;
                md_buf1 <= (others => '0');
                md_buf2 <= (others => '0');
                md.divisor1 <= (others => '0');
                md.divisor2 <= (others => '0');
                md.divisor3 <= (others => '0');
                div_running_v := '0';
                md.div_ready <= '0';
                md.outsign <= '0';
            elsif rising_edge(I_clk) then 
                -- If start and dividing...
                md.div_ready <= '0';
                if id_ex.md_start = '1' and id_ex.md_op(2) = '1' and control.trap_request = '0' and control.stall_on_trigger = '0' then
                    -- Signal that we are running
                    div_running_v := '1';
                    -- For restarting the division
                    count_v := 0;
                end if;
                if div_running_v = '1' then
                    case count_v is 
                        when 0 =>
                            md_buf1 <= (others => '0');
                            -- If signed divide, check for negative
                            -- value and make it positive
                            if id_ex.md_op(0) = '0' and a_v(31) = '1' then
                                md_buf2 <= unsigned(not a_v) + 1;
                            else
                                md_buf2 <= unsigned(a_v);
                            end if;
                            -- Load the divisor x1, divisor x2 and divisor x3
                            if id_ex.md_op(0) = '0' and b_v(31) = '1' then
                                md.divisor1 <= "00" & (unsigned(not b_v) + 1);
                                md.divisor2 <= ("0" & (unsigned(not b_v) + 1) & "0");
                                md.divisor3 <= ("0" & (unsigned(not b_v) + 1) & "0") + ("00" & (unsigned(not b_v) + 1));
                            else
                                md.divisor1 <= ("00" & unsigned(b_v));
                                md.divisor2 <= ("0" & unsigned(b_v) & "0");
                                md.divisor3 <= ("0" & unsigned(b_v) & "0") + ("00" & unsigned(b_v));
                            end if;
                            count_v := 1;
                            md.div_ready <= '0';
                            -- Determine the sign of the quotient and remainder
                            if (id_ex.md_op(0) = '0' and id_ex.md_op(1) = '0' and (a_v(31) /= b_v(31)) and b_v /= all_zeros_c) or (id_ex.md_op(0) = '0' and id_ex.md_op(1) = '1' and a_v(31) = '1') then
                                md.outsign <= '1';
                            else
                                md.outsign <= '0';
                            end if;
                        when others =>
                            -- Do the divide
                            -- First check is divisor x3 can be subtracted...
                            if md.buf(63 downto 30) >= md.divisor3 then
                                md_buf1(63 downto 32) <= md.buf(61 downto 30) - md.divisor3(31 downto 0);
                                md_buf2 <= md_buf2(29 downto 0) & "11";
                            -- Then check is divisor x2 can be subtracted...
                            elsif md.buf(63 downto 30) >= md.divisor2 then
                                md_buf1(63 downto 32) <= md.buf(61 downto 30) - md.divisor2(31 downto 0);
                                md_buf2 <= md_buf2(29 downto 0) & "10";
                            -- Then check is divisor x1 can be subtracted...
                            elsif md.buf(63 downto 30) >= md.divisor1 then
                                md_buf1(63 downto 32) <= md.buf(61 downto 30) - md.divisor1(31 downto 0);
                                md_buf2 <= md_buf2(29 downto 0) & "01";
                            -- Else no subtraction can be performed.
                            else
                                -- Shift in 0 (00)
                                md.buf <= md.buf(61 downto 0) & "00";
                            end if;
                            -- Do this 16 times (32 bit/2 bits at a time, output in last cycle)
                            if count_v /= 16 then
                                -- Signal ready one clock before
                                if count_v = 15 then
                                    md.div_ready <= '1';
                                end if;
                                count_v := count_v + 1;
                            else
                                -- Ready, show the result
                                count_v := 0;
                                div_running_v := '0';
                            end if;
                    end case;
                end if;
            end if;
-- synthesis translate_off
            md.count <= count_v;
-- synthesis translate_on
        end process;
        end generate;
        
        fast_div_not: if not FAST_DIVIDE generate
        -- Division unit, retires one bit at a time
        process (I_clk, I_areset, control, ex_wb, id_ex) is
        variable a_v, b_v : data_type;
        variable div_running_v : std_logic;  
        variable count_v : integer range 0 to 32;
        begin
            -- Check if forwarding result is needed
            if control.forwarda = '1' then
                a_v := (ex_wb.rddata);
            else
                a_v := (id_ex.rs1data);
            end if;
                
            if control.forwardb = '1' then
                b_v := (ex_wb.rddata);
            else
                b_v := (id_ex.rs2data);
            end if;
            
            if I_areset = '1' then
                -- Reset everything
                count_v := 0;
                md_buf1 <= (others => '0');
                md_buf2 <= (others => '0');
                md.divisor <= (others => '0');
                div_running_v := '0';
                md.div_ready <= '0';
                md.outsign <= '0';
            elsif rising_edge(I_clk) then 
                -- If start and dividing...
                md.div_ready <= '0';
                if id_ex.md_start = '1' and id_ex.md_op(2) = '1' and control.trap_request = '0' and control.stall_on_trigger = '0' then
                    div_running_v := '1';
                    count_v := 0;
                end if;
                if div_running_v = '1' then
                    case count_v is 
                        when 0 => 
                            md_buf1 <= (others => '0');
                            -- If signed divide, check for negative
                            -- value and make it positive
                            if id_ex.md_op(0) = '0' and a_v(31) = '1' then
                                md_buf2 <= unsigned(not a_v) + 1;
                            else
                                md_buf2 <= unsigned(a_v);
                            end if;
                            if id_ex.md_op(0) = '0' and b_v(31) = '1' then
                                md.divisor <= unsigned(not b_v) + 1;
                            else
                                md.divisor <= unsigned(b_v); 
                            end if;
                            count_v := 1; 
                            md.div_ready <= '0';
                            -- Determine the result sign
                            if (id_ex.md_op(0) = '0' and id_ex.md_op(1) = '0' and (a_v(31) /= b_v(31)) and b_v /= all_zeros_c) or (id_ex.md_op(0) = '0' and id_ex.md_op(1) = '1' and a_v(31) = '1') then
                                md.outsign <= '1';
                            else
                                md.outsign <= '0';
                            end if;

                        when others =>
                            -- Do the division
                            if md.buf(62 downto 31) >= md.divisor then 
                                md_buf1 <= '0' & (md.buf(61 downto 31) - md.divisor(30 downto 0)); 
                                md_buf2 <= md_buf2(30 downto 0) & '1'; 
                            else 
                                md.buf <= md.buf(62 downto 0) & '0'; 
                            end if;
                            -- Do this 32 times, last one outputs the result
                            if count_v /= 32 then 
                                -- Signal ready one clock before
                                if count_v = 31 then
                                    md.div_ready <= '1';
                                end if;
                                count_v := count_v + 1;
                            else
                                -- Signal ready
                                count_v := 0;
                                div_running_v := '0';
                            end if; 
                    end case; 
                end if;
            end if;
-- synthesis translate_off
            -- Only to view in simulator
            md.count <= count_v;
-- synthesis translate_on
        end process;
        end generate;
        
        -- Select the correct signedness of the results
        process (md.outsign, md_buf2, md_buf1) is
        begin
            if md.outsign = '1' then
                md.quotient <= not md_buf2 + 1;
                md.remainder <= not md_buf1 + 1;
            else
                md.quotient <= md_buf2;
                md.remainder <= md_buf1; 
            end if;
        end process;

        -- Select the divider output
        md.div <= std_logic_vector(md.remainder) when id_ex.md_op(1) = '1' else std_logic_vector(md.quotient);
        
        -- Signal that we are ready
        md.ready <= md.div_ready or md.mul_ready;
        
    end generate; -- generate MD unit
    
    -- If we don't have an MD unit, set some signals
    -- to default values. The synthesizer will remove the hardware.
    muldivgennot: if not HAVE_MULDIV generate
        md.ready <= '0';
        md.mul <= (others => '0');
        md.div <= (others => '0');
    end generate;

    -- Save a copy of the result for data forwarding
    process (I_clk, I_areset) is
    begin
        if I_areset = '1' then
            ex_wb.rd <= (others => '0');
            ex_wb.rd_en <= '0';
            ex_wb.rddata <= (others => '0');
            ex_wb.pc <= (others => '0');
        elsif rising_edge(I_clk) then
            if control.stall = '1' or control.stall_on_trigger = '1' then
                null;
            else
                ex_wb.rd_en <= id_ex.rd_en;
                if id_ex.rd_en = '1' and control.trap_request = '0' then
                    ex_wb.rddata <= id_ex.result;
                    ex_wb.rd <= id_ex.rd;
                end if;
                ex_wb.pc <= id_ex.pc;
            end if;
        end if;       
    end process;


    --
    -- Memory interface block
    --

    -- This is the interface between the core and the memory (ROM, RAM, I/O)
    -- Memory access type and size are computed in the instruction decoding unit
    process (I_clk, I_areset, I_bus_response.ready, control, id_ex, ex_wb, I_dm_core_data_request) is
    variable address_v : unsigned(31 downto 0);
    begin
        
        -- If we're in debug
        if control.indebug = '1' then
            address_v := unsigned(I_dm_core_data_request.address);
        -- Check if we need forward or not
        elsif control.forwarda = '1' then
            address_v := unsigned(ex_wb.rddata);
            address_v := address_v + unsigned(id_ex.imm);
        else
            address_v := unsigned(id_ex.rs1data);
            address_v := address_v + unsigned(id_ex.imm);
        end if;

        if I_areset = '1' then
            O_bus_request.size <= memsize_unknown;
            O_bus_request.acc <= memaccess_nop;
            O_bus_request.data <= (others => '0');
            csr_transfer.address_to_mtval <= (others => '0');
        elsif rising_edge(I_clk) then
            -- If current transaction is completed, reset the bus
            if I_bus_response.ready = '1' then
                O_bus_request.size <= memsize_unknown;
                O_bus_request.acc <= memaccess_nop;
                O_bus_request.data <= (others => '0');
                csr_transfer.address_to_mtval <= (others => '0');
            -- else clock in the credentials for memory access
            else
                -- Debug
                if control.indebug = '1' then
                    if I_dm_core_data_request.readmem = '1' then
                        O_bus_request.acc <= memaccess_read;
                    elsif I_dm_core_data_request.writemem = '1' then
                        O_bus_request.acc <= memaccess_write;
                    else
                        O_bus_request.acc <= memaccess_nop;
                    end if;
                    if (I_dm_core_data_request.readmem or I_dm_core_data_request.writemem) = '0' then
                        O_bus_request.size <= memsize_unknown;
                    elsif I_dm_core_data_request.size = "00" then
                        O_bus_request.size <= memsize_byte;
                    elsif I_dm_core_data_request.size = "01" then
                        O_bus_request.size <= memsize_halfword;
                    elsif I_dm_core_data_request.size = "10" then
                        O_bus_request.size <= memsize_word;
                    else
                        O_bus_request.size <= memsize_unknown;
                    end if;
                -- Disable the bus when flushing or trap
                elsif control.flush = '1' or control.trap_request = '1' or control.stall_on_trigger = '1' then
                    O_bus_request.acc <= memaccess_nop;
                    O_bus_request.size <= memsize_unknown;
                else
                    O_bus_request.acc <= id_ex.memaccess;
                    O_bus_request.size <= id_ex.memsize;
                end if;

                -- In case of a trap, record the memory address in MTVAL CSR
                csr_transfer.address_to_mtval <= std_logic_vector(address_v);
                
                -- Data out to memory
                if control.indebug = '1' then
                    O_bus_request.data <= I_dm_core_data_request.data;
                elsif control.forwardb = '1' then
                    O_bus_request.data <= ex_wb.rddata;
                else
                    O_bus_request.data <= id_ex.rs2data;
                end if;
            end if;
        end if;
    end process;
    -- Address of the memory operation, this is a simple copy
    -- outside the rising edge to make 1 register instead of 2
    O_bus_request.addr <= I_dm_core_data_request.address when control.indebug = '1' else csr_transfer.address_to_mtval;
    
    
    --
    -- Interface to the CSR
    --
    
    csr_access.op <= id_ex.csr_op;
    -- Set access parameters
    csr_access.address <= id_ex.csr_addr;
    csr_access.immrs1 <= id_ex.csr_immrs1;
    
--    -- Set the address of the CSR register
    process (control.forwarda, id_ex.rs1data, ex_wb.rddata) is
    begin
        -- Check if we need forward or not
        if control.forwarda = '1' then
            csr_access.dataout <= ex_wb.rddata;
        else
            csr_access.dataout <= id_ex.rs1data;
        end if;
       
    end process;
    
    
    --
    -- CSR - Control and Status Registers
    --
    
    process (I_clk, I_areset, csr_access, csr_reg,
             control, id_ex, I_bus_response.ready, md,
             I_dm_core_data_request, pc) is
    variable csr_addr_v : integer range 0 to csr_size-1;
    variable event3_v, event4_v, event5_v, event6_v, event7_v, event8_v, event9_v : boolean;
    variable csr_content_v : data_type;
    begin
    
        -- Event generators
        if HAVE_ZIHPM then
        event3_v := (csr_reg.mhpmevent3(0) = '1' and control.penalty = '1') or
                    (csr_reg.mhpmevent3(1) = '1' and control.stall = '1') or
                    (csr_reg.mhpmevent3(2) = '1' and id_ex.memaccess = memaccess_write and I_bus_response.ready = '1') or
                    (csr_reg.mhpmevent3(3) = '1' and id_ex.memaccess = memaccess_read and I_bus_response.ready = '1') or
                    (csr_reg.mhpmevent3(4) = '1' and control.ecall_request = '1') or
                    (csr_reg.mhpmevent3(5) = '1' and control.ebreak_request = '1') or
                    (csr_reg.mhpmevent3(6) = '1' and md.ready = '1');
        event4_v := (csr_reg.mhpmevent4(0) = '1' and control.penalty = '1') or
                    (csr_reg.mhpmevent4(1) = '1' and control.stall = '1') or
                    (csr_reg.mhpmevent4(2) = '1' and id_ex.memaccess = memaccess_write and I_bus_response.ready = '1') or
                    (csr_reg.mhpmevent4(3) = '1' and id_ex.memaccess = memaccess_read and I_bus_response.ready = '1') or
                    (csr_reg.mhpmevent4(4) = '1' and control.ecall_request = '1') or
                    (csr_reg.mhpmevent4(5) = '1' and control.ebreak_request = '1') or
                    (csr_reg.mhpmevent4(6) = '1' and md.ready = '1');
        event5_v := (csr_reg.mhpmevent5(0) = '1' and control.penalty = '1') or
                    (csr_reg.mhpmevent5(1) = '1' and control.stall = '1') or
                    (csr_reg.mhpmevent5(2) = '1' and id_ex.memaccess = memaccess_write and I_bus_response.ready = '1') or
                    (csr_reg.mhpmevent5(3) = '1' and id_ex.memaccess = memaccess_read and I_bus_response.ready = '1') or
                    (csr_reg.mhpmevent5(4) = '1' and control.ecall_request = '1') or
                    (csr_reg.mhpmevent5(5) = '1' and control.ebreak_request = '1') or
                    (csr_reg.mhpmevent5(6) = '1' and md.ready = '1');
        event6_v := (csr_reg.mhpmevent6(0) = '1' and control.penalty = '1') or
                    (csr_reg.mhpmevent6(1) = '1' and control.stall = '1') or
                    (csr_reg.mhpmevent6(2) = '1' and id_ex.memaccess = memaccess_write and I_bus_response.ready = '1') or
                    (csr_reg.mhpmevent6(3) = '1' and id_ex.memaccess = memaccess_read and I_bus_response.ready = '1') or
                    (csr_reg.mhpmevent6(4) = '1' and control.ecall_request = '1') or
                    (csr_reg.mhpmevent6(5) = '1' and control.ebreak_request = '1') or
                    (csr_reg.mhpmevent6(6) = '1' and md.ready = '1');
        event7_v := (csr_reg.mhpmevent7(0) = '1' and control.penalty = '1') or
                    (csr_reg.mhpmevent7(1) = '1' and control.stall = '1') or
                    (csr_reg.mhpmevent7(2) = '1' and id_ex.memaccess = memaccess_write and I_bus_response.ready = '1') or
                    (csr_reg.mhpmevent7(3) = '1' and id_ex.memaccess = memaccess_read and I_bus_response.ready = '1') or
                    (csr_reg.mhpmevent7(4) = '1' and control.ecall_request = '1') or
                    (csr_reg.mhpmevent7(5) = '1' and control.ebreak_request = '1') or
                    (csr_reg.mhpmevent7(6) = '1' and md.ready = '1');
        event8_v := (csr_reg.mhpmevent8(0) = '1' and control.penalty = '1') or
                    (csr_reg.mhpmevent8(1) = '1' and control.stall = '1') or
                    (csr_reg.mhpmevent8(2) = '1' and id_ex.memaccess = memaccess_write and I_bus_response.ready = '1') or
                    (csr_reg.mhpmevent8(3) = '1' and id_ex.memaccess = memaccess_read and I_bus_response.ready = '1') or
                    (csr_reg.mhpmevent8(4) = '1' and control.ecall_request = '1') or
                    (csr_reg.mhpmevent8(5) = '1' and control.ebreak_request = '1') or
                    (csr_reg.mhpmevent8(6) = '1' and md.ready = '1');
        event9_v := (csr_reg.mhpmevent9(0) = '1' and control.penalty = '1') or
                    (csr_reg.mhpmevent9(1) = '1' and control.stall = '1') or
                    (csr_reg.mhpmevent9(2) = '1' and id_ex.memaccess = memaccess_write and I_bus_response.ready = '1') or
                    (csr_reg.mhpmevent9(3) = '1' and id_ex.memaccess = memaccess_read and I_bus_response.ready = '1') or
                    (csr_reg.mhpmevent9(4) = '1' and control.ecall_request = '1') or
                    (csr_reg.mhpmevent9(5) = '1' and control.ebreak_request = '1') or
                    (csr_reg.mhpmevent9(6) = '1' and md.ready = '1');
        else
            event3_v := false;
            event4_v := false;
            event5_v := false;
            event6_v := false;
            event7_v := false;
            event8_v := false;
            event9_v := false;
        end if;
                    
        -- Fetch CSR address
        if control.indebug = '1' then
            csr_addr_v := to_integer(unsigned(I_dm_core_data_request.address(11 downto 0)));
        else
            csr_addr_v := to_integer(unsigned(csr_access.address));
        end if;

        -- Check for correct access
        -- This is troublesome on Eclipse, so if we are in debug, unimplemented
        -- registers return -1 as value
        if control.indebug = '0' and csr_access.op = csr_nop then
            control.illegal_instruction_csr <= '0';
        elsif control.indebug = '0' and csr_access.address(11 downto 10) = "11" and (csr_access.op = csr_rw or csr_access.op = csr_rwi or csr_access.immrs1 /= "00000") then
            control.illegal_instruction_csr <= '1';
        elsif control.indebug = '1' and ((I_dm_core_data_request.writecsr = '0' and I_dm_core_data_request.readcsr = '0') or OCD_CSR_CHECK_DISABLE) then
            control.illegal_instruction_csr <= '0';
        elsif csr_addr_v = cycle_addr or
              csr_addr_v = time_addr or
              csr_addr_v = instret_addr or
              csr_addr_v = cycleh_addr or
              csr_addr_v = timeh_addr or
              csr_addr_v = instreth_addr or

             (csr_addr_v = hpmcounter3_addr and HAVE_ZIHPM) or
             (csr_addr_v = hpmcounter3h_addr and HAVE_ZIHPM) or
             (csr_addr_v = hpmcounter4_addr and HAVE_ZIHPM) or
             (csr_addr_v = hpmcounter4h_addr and HAVE_ZIHPM) or
             (csr_addr_v = hpmcounter5_addr and HAVE_ZIHPM) or
             (csr_addr_v = hpmcounter5h_addr and HAVE_ZIHPM) or
             (csr_addr_v = hpmcounter6_addr and HAVE_ZIHPM) or
             (csr_addr_v = hpmcounter6h_addr and HAVE_ZIHPM) or
             (csr_addr_v = hpmcounter7_addr and HAVE_ZIHPM) or
             (csr_addr_v = hpmcounter7h_addr and HAVE_ZIHPM) or
             (csr_addr_v = hpmcounter8_addr and HAVE_ZIHPM) or
             (csr_addr_v = hpmcounter8h_addr and HAVE_ZIHPM) or
             (csr_addr_v = hpmcounter9_addr and HAVE_ZIHPM) or
             (csr_addr_v = hpmcounter9h_addr and HAVE_ZIHPM) or
             (csr_addr_v = hpmcounter10_addr and HAVE_ZIHPM) or
             (csr_addr_v = hpmcounter10h_addr and HAVE_ZIHPM) or
             (csr_addr_v = hpmcounter11_addr and HAVE_ZIHPM) or
             (csr_addr_v = hpmcounter11h_addr and HAVE_ZIHPM) or
             (csr_addr_v = hpmcounter12_addr and HAVE_ZIHPM) or
             (csr_addr_v = hpmcounter12h_addr and HAVE_ZIHPM) or
             (csr_addr_v = hpmcounter13_addr and HAVE_ZIHPM) or
             (csr_addr_v = hpmcounter13h_addr and HAVE_ZIHPM) or
             (csr_addr_v = hpmcounter14_addr and HAVE_ZIHPM) or
             (csr_addr_v = hpmcounter14h_addr and HAVE_ZIHPM) or
             (csr_addr_v = hpmcounter15_addr and HAVE_ZIHPM) or
             (csr_addr_v = hpmcounter15h_addr and HAVE_ZIHPM) or
             (csr_addr_v = hpmcounter16_addr and HAVE_ZIHPM) or
             (csr_addr_v = hpmcounter16h_addr and HAVE_ZIHPM) or
             (csr_addr_v = hpmcounter17_addr and HAVE_ZIHPM) or
             (csr_addr_v = hpmcounter17h_addr and HAVE_ZIHPM) or
             (csr_addr_v = hpmcounter18_addr and HAVE_ZIHPM) or
             (csr_addr_v = hpmcounter18h_addr and HAVE_ZIHPM) or
             (csr_addr_v = hpmcounter19_addr and HAVE_ZIHPM) or
             (csr_addr_v = hpmcounter19h_addr and HAVE_ZIHPM) or
             (csr_addr_v = hpmcounter20_addr and HAVE_ZIHPM) or
             (csr_addr_v = hpmcounter20h_addr and HAVE_ZIHPM) or
             (csr_addr_v = hpmcounter21_addr and HAVE_ZIHPM) or
             (csr_addr_v = hpmcounter21h_addr and HAVE_ZIHPM) or
             (csr_addr_v = hpmcounter22_addr and HAVE_ZIHPM) or
             (csr_addr_v = hpmcounter22h_addr and HAVE_ZIHPM) or
             (csr_addr_v = hpmcounter23_addr and HAVE_ZIHPM) or
             (csr_addr_v = hpmcounter23h_addr and HAVE_ZIHPM) or
             (csr_addr_v = hpmcounter24_addr and HAVE_ZIHPM) or
             (csr_addr_v = hpmcounter24h_addr and HAVE_ZIHPM) or
             (csr_addr_v = hpmcounter25_addr and HAVE_ZIHPM) or
             (csr_addr_v = hpmcounter25h_addr and HAVE_ZIHPM) or
             (csr_addr_v = hpmcounter26_addr and HAVE_ZIHPM) or
             (csr_addr_v = hpmcounter26h_addr and HAVE_ZIHPM) or
             (csr_addr_v = hpmcounter27_addr and HAVE_ZIHPM) or
             (csr_addr_v = hpmcounter27h_addr and HAVE_ZIHPM) or
             (csr_addr_v = hpmcounter28_addr and HAVE_ZIHPM) or
             (csr_addr_v = hpmcounter28h_addr and HAVE_ZIHPM) or
             (csr_addr_v = hpmcounter29_addr and HAVE_ZIHPM) or
             (csr_addr_v = hpmcounter29h_addr and HAVE_ZIHPM) or
             (csr_addr_v = hpmcounter30_addr and HAVE_ZIHPM) or
             (csr_addr_v = hpmcounter30h_addr and HAVE_ZIHPM) or
             (csr_addr_v = hpmcounter31_addr and HAVE_ZIHPM) or
             (csr_addr_v = hpmcounter31h_addr and HAVE_ZIHPM) or
              
              csr_addr_v = mvendorid_addr or
              csr_addr_v = marchid_addr or
              csr_addr_v = mimpid_addr or
              csr_addr_v = mhartid_addr or
              csr_addr_v = mconfigptr_addr or
              csr_addr_v = mstatus_addr or
              csr_addr_v = misa_addr or
              csr_addr_v = mie_addr or
              csr_addr_v = mtvec_addr or
              csr_addr_v = mcounteren_addr or
              csr_addr_v = mstatush_addr or
              csr_addr_v = mcountinhibit_addr or
              csr_addr_v = mscratch_addr or
              csr_addr_v = mepc_addr or
              csr_addr_v = mcause_addr or
              csr_addr_v = mtval_addr or
              csr_addr_v = mip_addr or
              csr_addr_v = mcycle_addr or
              csr_addr_v = minstret_addr or
              csr_addr_v = mcycleh_addr or
              csr_addr_v = minstreth_addr or
             (csr_addr_v = mhpmcounter3_addr and HAVE_ZIHPM) or
             (csr_addr_v = mhpmcounter3h_addr  and HAVE_ZIHPM) or
             (csr_addr_v = mhpmevent3_addr and HAVE_ZIHPM) or
             (csr_addr_v = mhpmcounter4_addr and HAVE_ZIHPM) or
             (csr_addr_v = mhpmcounter4h_addr  and HAVE_ZIHPM) or
             (csr_addr_v = mhpmevent4_addr and HAVE_ZIHPM) or
             (csr_addr_v = mhpmcounter5_addr and HAVE_ZIHPM) or
             (csr_addr_v = mhpmcounter5h_addr  and HAVE_ZIHPM) or
             (csr_addr_v = mhpmevent5_addr and HAVE_ZIHPM) or
             (csr_addr_v = mhpmcounter6_addr and HAVE_ZIHPM) or
             (csr_addr_v = mhpmcounter6h_addr  and HAVE_ZIHPM) or
             (csr_addr_v = mhpmevent6_addr and HAVE_ZIHPM) or
             (csr_addr_v = mhpmcounter7_addr and HAVE_ZIHPM) or
             (csr_addr_v = mhpmcounter7h_addr  and HAVE_ZIHPM) or
             (csr_addr_v = mhpmevent7_addr and HAVE_ZIHPM) or
             (csr_addr_v = mhpmcounter8_addr and HAVE_ZIHPM) or
             (csr_addr_v = mhpmcounter8h_addr  and HAVE_ZIHPM) or
             (csr_addr_v = mhpmevent8_addr and HAVE_ZIHPM) or
             (csr_addr_v = mhpmcounter9_addr and HAVE_ZIHPM) or
             (csr_addr_v = mhpmcounter9h_addr  and HAVE_ZIHPM) or
             (csr_addr_v = mhpmevent9_addr and HAVE_ZIHPM) or
             (csr_addr_v = mhpmcounter10_addr and HAVE_ZIHPM) or
             (csr_addr_v = mhpmcounter10h_addr  and HAVE_ZIHPM) or
             (csr_addr_v = mhpmevent10_addr and HAVE_ZIHPM) or
             (csr_addr_v = mhpmcounter11_addr and HAVE_ZIHPM) or
             (csr_addr_v = mhpmcounter11h_addr  and HAVE_ZIHPM) or
             (csr_addr_v = mhpmevent11_addr and HAVE_ZIHPM) or
             (csr_addr_v = mhpmcounter12_addr and HAVE_ZIHPM) or
             (csr_addr_v = mhpmcounter12h_addr  and HAVE_ZIHPM) or
             (csr_addr_v = mhpmevent12_addr and HAVE_ZIHPM) or
             (csr_addr_v = mhpmcounter13_addr and HAVE_ZIHPM) or
             (csr_addr_v = mhpmcounter13h_addr  and HAVE_ZIHPM) or
             (csr_addr_v = mhpmevent13_addr and HAVE_ZIHPM) or
             (csr_addr_v = mhpmcounter14_addr and HAVE_ZIHPM) or
             (csr_addr_v = mhpmcounter14h_addr  and HAVE_ZIHPM) or
             (csr_addr_v = mhpmevent14_addr and HAVE_ZIHPM) or
             (csr_addr_v = mhpmcounter15_addr and HAVE_ZIHPM) or
             (csr_addr_v = mhpmcounter15h_addr  and HAVE_ZIHPM) or
             (csr_addr_v = mhpmevent15_addr and HAVE_ZIHPM) or
             (csr_addr_v = mhpmcounter16_addr and HAVE_ZIHPM) or
             (csr_addr_v = mhpmcounter16h_addr  and HAVE_ZIHPM) or
             (csr_addr_v = mhpmevent16_addr and HAVE_ZIHPM) or
             (csr_addr_v = mhpmcounter17_addr and HAVE_ZIHPM) or
             (csr_addr_v = mhpmcounter17h_addr  and HAVE_ZIHPM) or
             (csr_addr_v = mhpmevent17_addr and HAVE_ZIHPM) or
             (csr_addr_v = mhpmcounter18_addr and HAVE_ZIHPM) or
             (csr_addr_v = mhpmcounter18h_addr  and HAVE_ZIHPM) or
             (csr_addr_v = mhpmevent18_addr and HAVE_ZIHPM) or
             (csr_addr_v = mhpmcounter19_addr and HAVE_ZIHPM) or
             (csr_addr_v = mhpmcounter19h_addr  and HAVE_ZIHPM) or
             (csr_addr_v = mhpmevent19_addr and HAVE_ZIHPM) or
             (csr_addr_v = mhpmcounter20_addr and HAVE_ZIHPM) or
             (csr_addr_v = mhpmcounter20h_addr  and HAVE_ZIHPM) or
             (csr_addr_v = mhpmevent20_addr and HAVE_ZIHPM) or
             (csr_addr_v = mhpmcounter21_addr and HAVE_ZIHPM) or
             (csr_addr_v = mhpmcounter21h_addr  and HAVE_ZIHPM) or
             (csr_addr_v = mhpmevent21_addr and HAVE_ZIHPM) or
             (csr_addr_v = mhpmcounter22_addr and HAVE_ZIHPM) or
             (csr_addr_v = mhpmcounter22h_addr  and HAVE_ZIHPM) or
             (csr_addr_v = mhpmevent22_addr and HAVE_ZIHPM) or
             (csr_addr_v = mhpmcounter23_addr and HAVE_ZIHPM) or
             (csr_addr_v = mhpmcounter23h_addr  and HAVE_ZIHPM) or
             (csr_addr_v = mhpmevent23_addr and HAVE_ZIHPM) or
             (csr_addr_v = mhpmcounter24_addr and HAVE_ZIHPM) or
             (csr_addr_v = mhpmcounter24h_addr  and HAVE_ZIHPM) or
             (csr_addr_v = mhpmevent24_addr and HAVE_ZIHPM) or
             (csr_addr_v = mhpmcounter25_addr and HAVE_ZIHPM) or
             (csr_addr_v = mhpmcounter25h_addr  and HAVE_ZIHPM) or
             (csr_addr_v = mhpmevent25_addr and HAVE_ZIHPM) or
             (csr_addr_v = mhpmcounter26_addr and HAVE_ZIHPM) or
             (csr_addr_v = mhpmcounter26h_addr  and HAVE_ZIHPM) or
             (csr_addr_v = mhpmevent26_addr and HAVE_ZIHPM) or
             (csr_addr_v = mhpmcounter27_addr and HAVE_ZIHPM) or
             (csr_addr_v = mhpmcounter27h_addr  and HAVE_ZIHPM) or
             (csr_addr_v = mhpmevent27_addr and HAVE_ZIHPM) or
             (csr_addr_v = mhpmcounter28_addr and HAVE_ZIHPM) or
             (csr_addr_v = mhpmcounter28h_addr  and HAVE_ZIHPM) or
             (csr_addr_v = mhpmevent28_addr and HAVE_ZIHPM) or
             (csr_addr_v = mhpmcounter29_addr and HAVE_ZIHPM) or
             (csr_addr_v = mhpmcounter29h_addr  and HAVE_ZIHPM) or
             (csr_addr_v = mhpmevent29_addr and HAVE_ZIHPM) or
             (csr_addr_v = mhpmcounter30_addr and HAVE_ZIHPM) or
             (csr_addr_v = mhpmcounter30h_addr  and HAVE_ZIHPM) or
             (csr_addr_v = mhpmevent30_addr and HAVE_ZIHPM) or
             (csr_addr_v = mhpmcounter31_addr and HAVE_ZIHPM) or
             (csr_addr_v = mhpmcounter31h_addr  and HAVE_ZIHPM) or
             (csr_addr_v = mhpmevent31_addr and HAVE_ZIHPM) or
             
             (csr_addr_v = dcsr_addr and control.indebug = '1' and HAVE_OCD) or
             (csr_addr_v = dpc_addr and control.indebug = '1' and HAVE_OCD) or
             (csr_addr_v = tselect_addr and HAVE_OCD) or
             (csr_addr_v = tdata1_addr and HAVE_OCD) or
             (csr_addr_v = tdata2_addr and HAVE_OCD) or
             (csr_addr_v = tinfo_addr and HAVE_OCD) or
             
              csr_addr_v = mxhw_addr or
              csr_addr_v = mxspeed_addr then
            control.illegal_instruction_csr <= '0';
        else 
            control.illegal_instruction_csr <= '1';
        end if;

        -- Output to ALU
        case csr_addr_v is
            when cycle_addr         => csr_access.datain <= csr_reg.mcycle;
            -- 'mtime' does not exists, but 'time' is a reserved keyword...
            when time_addr          => csr_access.datain <= csr_reg.mtime;
            when instret_addr       => csr_access.datain <= csr_reg.minstret;
            when cycleh_addr        => csr_access.datain <= csr_reg.mcycleh;
            -- to be in sync with 'mtime'
            when timeh_addr         => csr_access.datain <= csr_reg.mtimeh;
            when instreth_addr      => csr_access.datain <= csr_reg.minstreth;
            when hpmcounter3_addr   => csr_access.datain <= csr_reg.mhpmcounter3;
            when hpmcounter3h_addr  => csr_access.datain <= csr_reg.mhpmcounter3h;
            when hpmcounter4_addr   => csr_access.datain <= csr_reg.mhpmcounter4;
            when hpmcounter4h_addr  => csr_access.datain <= csr_reg.mhpmcounter4h;
            when hpmcounter5_addr   => csr_access.datain <= csr_reg.mhpmcounter5;
            when hpmcounter5h_addr  => csr_access.datain <= csr_reg.mhpmcounter5h;
            when hpmcounter6_addr   => csr_access.datain <= csr_reg.mhpmcounter6;
            when hpmcounter6h_addr  => csr_access.datain <= csr_reg.mhpmcounter6h;
            when hpmcounter7_addr   => csr_access.datain <= csr_reg.mhpmcounter7;
            when hpmcounter7h_addr  => csr_access.datain <= csr_reg.mhpmcounter7h;
            when hpmcounter8_addr   => csr_access.datain <= csr_reg.mhpmcounter8;
            when hpmcounter8h_addr  => csr_access.datain <= csr_reg.mhpmcounter8h;
            when hpmcounter9_addr   => csr_access.datain <= csr_reg.mhpmcounter9;
            when hpmcounter9h_addr  => csr_access.datain <= csr_reg.mhpmcounter9h;
            when mvendorid_addr     => csr_access.datain <= csr_reg.mvendorid;
            when marchid_addr       => csr_access.datain <= csr_reg.marchid;
            when mimpid_addr        => csr_access.datain <= csr_reg.mimpid;
            when mhartid_addr       => csr_access.datain <= csr_reg.mhartid;
            when mstatus_addr       => csr_access.datain <= csr_reg.mstatus;
            when mstatush_addr      => csr_access.datain <= csr_reg.mstatush;
            when misa_addr          => csr_access.datain <= csr_reg.misa;
            when mie_addr           => csr_access.datain <= csr_reg.mie;
            when mtvec_addr         => csr_access.datain <= csr_reg.mtvec;
            when mcycle_addr        => csr_access.datain <= csr_reg.mcycle;
            when minstret_addr      => csr_access.datain <= csr_reg.minstret;
            when mcycleh_addr       => csr_access.datain <= csr_reg.mcycleh;
            when minstreth_addr     => csr_access.datain <= csr_reg.minstreth;
            when mcountinhibit_addr => csr_access.datain <= csr_reg.mcountinhibit;
            when mscratch_addr      => csr_access.datain <= csr_reg.mscratch;
            when mepc_addr          => csr_access.datain <= csr_reg.mepc;
            when mcause_addr        => csr_access.datain <= csr_reg.mcause;
            when mtval_addr         => csr_access.datain <= csr_reg.mtval;
            when mip_addr           => csr_access.datain <= csr_reg.mip;
            when mconfigptr_addr    => csr_access.datain <= csr_reg.mconfigptr;
            when mhpmcounter3_addr  => csr_access.datain <= csr_reg.mhpmcounter3;
            when mhpmcounter3h_addr => csr_access.datain <= csr_reg.mhpmcounter3h;
            when mhpmevent3_addr    => csr_access.datain <= csr_reg.mhpmevent3;
            when mhpmcounter4_addr  => csr_access.datain <= csr_reg.mhpmcounter4;
            when mhpmcounter4h_addr => csr_access.datain <= csr_reg.mhpmcounter4h;
            when mhpmevent4_addr    => csr_access.datain <= csr_reg.mhpmevent4;
            when mhpmcounter5_addr  => csr_access.datain <= csr_reg.mhpmcounter5;
            when mhpmcounter5h_addr => csr_access.datain <= csr_reg.mhpmcounter5h;
            when mhpmevent5_addr    => csr_access.datain <= csr_reg.mhpmevent5;
            when mhpmcounter6_addr  => csr_access.datain <= csr_reg.mhpmcounter6;
            when mhpmcounter6h_addr => csr_access.datain <= csr_reg.mhpmcounter6h;
            when mhpmevent6_addr    => csr_access.datain <= csr_reg.mhpmevent6;
            when mhpmcounter7_addr  => csr_access.datain <= csr_reg.mhpmcounter7;
            when mhpmcounter7h_addr => csr_access.datain <= csr_reg.mhpmcounter7h;
            when mhpmevent7_addr    => csr_access.datain <= csr_reg.mhpmevent7;
            when mhpmcounter8_addr  => csr_access.datain <= csr_reg.mhpmcounter8;
            when mhpmcounter8h_addr => csr_access.datain <= csr_reg.mhpmcounter8h;
            when mhpmevent8_addr    => csr_access.datain <= csr_reg.mhpmevent8;
            when mhpmcounter9_addr  => csr_access.datain <= csr_reg.mhpmcounter9;
            when mhpmcounter9h_addr => csr_access.datain <= csr_reg.mhpmcounter9h;
            when mhpmevent9_addr    => csr_access.datain <= csr_reg.mhpmevent9;
            when dcsr_addr          => csr_access.datain <= csr_reg.dcsr;
            when dpc_addr           => csr_access.datain <= csr_reg.dpc;
            when tselect_addr       => csr_access.datain <= csr_reg.tselect;
            when tdata1_addr        => csr_access.datain <= csr_reg.tdata1;
            when tdata2_addr        => csr_access.datain <= csr_reg.tdata2;
            when tinfo_addr         => csr_access.datain <= csr_reg.tinfo;
            when mxhw_addr          => csr_access.datain <= csr_reg.mxhw;
            when mxspeed_addr       => csr_access.datain <= csr_reg.mxspeed;
            when others             => csr_access.datain <= (others => '0');
        end case;
    
        -- Data to process in other registers
        -- Ignore the misa, mip, these are hard wired
        if I_areset = '1' then
            -- Reset the lot
            csr_reg.mstatus <= (others => '0');
            csr_reg.mie <= (others => '0');
            csr_reg.mtvec <= (others => '0');
            csr_reg.mcountinhibit <= (others => '0');
            csr_reg.mscratch <= (others => '0');
            csr_reg.mepc <= (others => '0');
            csr_reg.mcause <= (others => '0');
            csr_reg.mtval <= (others => '0');
            csr_reg.mtval <= (others => '0');
            csr_reg.mcycle <= (others => '0');
            csr_reg.mcycleh <= (others => '0');
            csr_reg.minstret <= (others => '0');
            csr_reg.minstreth <= (others => '0');
            csr_reg.mhpmcounter3 <= (others => '0');
            csr_reg.mhpmcounter3h <= (others => '0');
            csr_reg.mhpmevent3 <= (others => '0');
            csr_reg.mhpmcounter4 <= (others => '0');
            csr_reg.mhpmcounter4h <= (others => '0');
            csr_reg.mhpmevent4 <= (others => '0');
            csr_reg.mhpmcounter5 <= (others => '0');
            csr_reg.mhpmcounter5h <= (others => '0');
            csr_reg.mhpmevent5 <= (others => '0');
            csr_reg.mhpmcounter6 <= (others => '0');
            csr_reg.mhpmcounter6h <= (others => '0');
            csr_reg.mhpmevent6 <= (others => '0');
            csr_reg.mhpmcounter7 <= (others => '0');
            csr_reg.mhpmcounter7h <= (others => '0');
            csr_reg.mhpmevent7 <= (others => '0');
            csr_reg.mhpmcounter8 <= (others => '0');
            csr_reg.mhpmcounter8h <= (others => '0');
            csr_reg.mhpmevent8 <= (others => '0');
            csr_reg.mhpmcounter9 <= (others => '0');
            csr_reg.mhpmcounter9h <= (others => '0');
            csr_reg.mhpmevent9 <= (others => '0');
            csr_reg.dcsr <= (others => '0');
            csr_reg.dpc <= (others => '0');
            csr_reg.tdata1 <= (others => '0');
            csr_reg.tdata2 <= (others => '0');
        elsif rising_edge(I_clk) then
            --  Do we count cycles?
            if csr_reg.mcountinhibit(0) = '0' then
                csr_reg.mcycle <= std_logic_vector(unsigned(csr_reg.mcycle) + 1);
                if csr_reg.mcycle = all_ones_c then
                    csr_reg.mcycleh <= std_logic_vector(unsigned(csr_reg.mcycleh) + 1);
                end if;
            end if;
            -- Instruction retired?
            if control.instret = '1' then
                -- Do we count instructions retired?
                if csr_reg.mcountinhibit(2) = '0' then
                    csr_reg.minstret <= std_logic_vector(unsigned(csr_reg.minstret) + 1);
                    if csr_reg.minstret = all_ones_c then
                        csr_reg.minstreth <= std_logic_vector(unsigned(csr_reg.minstreth) + 1);
                    end if;
                end if;
            end if;
            -- Do we have performance counters?
            if HAVE_ZIHPM then
                if event3_v then
                    -- Do we count?
                    if csr_reg.mcountinhibit(3) = '0' then
                        csr_reg.mhpmcounter3 <= std_logic_vector(unsigned(csr_reg.mhpmcounter3) + 1);
                        if csr_reg.mhpmcounter3 = all_ones_c then
                            csr_reg.mhpmcounter3h <= std_logic_vector(unsigned(csr_reg.mhpmcounter3h) + 1);
                        end if;
                    end if;
                end if;
                if event4_v then
                    -- Do we count?
                    if csr_reg.mcountinhibit(4) = '0' then
                        csr_reg.mhpmcounter4 <= std_logic_vector(unsigned(csr_reg.mhpmcounter4) + 1);
                        if csr_reg.mhpmcounter4 = all_ones_c then
                            csr_reg.mhpmcounter4h <= std_logic_vector(unsigned(csr_reg.mhpmcounter4h) + 1);
                        end if;
                    end if;
                end if;
                if event5_v then
                    -- Do we count?
                    if csr_reg.mcountinhibit(5) = '0' then
                        csr_reg.mhpmcounter5 <= std_logic_vector(unsigned(csr_reg.mhpmcounter5) + 1);
                        if csr_reg.mhpmcounter5 = all_ones_c then
                            csr_reg.mhpmcounter5h <= std_logic_vector(unsigned(csr_reg.mhpmcounter5h) + 1);
                        end if;
                    end if;
                end if;
                if event6_v then
                    -- Do we count?
                    if csr_reg.mcountinhibit(6) = '0' then
                        csr_reg.mhpmcounter6 <= std_logic_vector(unsigned(csr_reg.mhpmcounter6) + 1);
                        if csr_reg.mhpmcounter6 = all_ones_c then
                            csr_reg.mhpmcounter6h <= std_logic_vector(unsigned(csr_reg.mhpmcounter6h) + 1);
                        end if;
                    end if;
                end if;
                if event7_v then
                    -- Do we count?
                    if csr_reg.mcountinhibit(7) = '0' then
                        csr_reg.mhpmcounter7 <= std_logic_vector(unsigned(csr_reg.mhpmcounter7) + 1);
                        if csr_reg.mhpmcounter7 = all_ones_c then
                            csr_reg.mhpmcounter7h <= std_logic_vector(unsigned(csr_reg.mhpmcounter7h) + 1);
                        end if;
                    end if;
                end if;
                if event8_v then
                    -- Do we count?
                    if csr_reg.mcountinhibit(8) = '0' then
                        csr_reg.mhpmcounter8 <= std_logic_vector(unsigned(csr_reg.mhpmcounter8) + 1);
                        if csr_reg.mhpmcounter8 = all_ones_c then
                            csr_reg.mhpmcounter8h <= std_logic_vector(unsigned(csr_reg.mhpmcounter8h) + 1);
                        end if;
                    end if;
                end if;
                if event9_v then
                    -- Do we count?
                    if csr_reg.mcountinhibit(9) = '0' then
                        csr_reg.mhpmcounter9 <= std_logic_vector(unsigned(csr_reg.mhpmcounter9) + 1);
                        if csr_reg.mhpmcounter9 = all_ones_c then
                            csr_reg.mhpmcounter9h <= std_logic_vector(unsigned(csr_reg.mhpmcounter9h) + 1);
                        end if;
                    end if;
                end if;
            end if;   -- /HAVE_ZIHPM
            
            -- If no trap is pending, then update the selected csr_reg.
            -- Needed because the instruction is restarted after MRET
            if csr_access.op /= csr_nop and control.trap_request = '0' and control.indebug = '0' and control.stall_on_trigger = '0' then
                -- Select the CSR
                case csr_addr_v is
                    when mcycle_addr => csr_content_v := csr_reg.mcycle;
                    when mcycleh_addr => csr_content_v := csr_reg.mcycleh;
                    when minstret_addr => csr_content_v := csr_reg.minstret;
                    when minstreth_addr => csr_content_v := csr_reg.minstreth;
                    when mhpmevent3_addr => csr_content_v := csr_reg.mhpmevent3;
                    when mhpmevent5_addr => csr_content_v := csr_reg.mhpmevent5;
                    when mhpmevent6_addr => csr_content_v := csr_reg.mhpmevent6;
                    when mhpmevent7_addr => csr_content_v := csr_reg.mhpmevent7;
                    when mhpmevent8_addr => csr_content_v := csr_reg.mhpmevent8;
                    when mhpmevent9_addr => csr_content_v := csr_reg.mhpmevent9;
                    when mhpmcounter3_addr => csr_content_v := csr_reg.mhpmcounter3;
                    when mhpmcounter4_addr => csr_content_v := csr_reg.mhpmcounter4;
                    when mhpmcounter5_addr => csr_content_v := csr_reg.mhpmcounter5;
                    when mhpmcounter6_addr => csr_content_v := csr_reg.mhpmcounter6;
                    when mhpmcounter7_addr => csr_content_v := csr_reg.mhpmcounter7;
                    when mhpmcounter8_addr => csr_content_v := csr_reg.mhpmcounter8;
                    when mhpmcounter9_addr => csr_content_v := csr_reg.mhpmcounter9;
                    when mhpmcounter3h_addr => csr_content_v := csr_reg.mhpmcounter3h;
                    when mhpmcounter4h_addr => csr_content_v := csr_reg.mhpmcounter4h;
                    when mhpmcounter5h_addr => csr_content_v := csr_reg.mhpmcounter5h;
                    when mhpmcounter6h_addr => csr_content_v := csr_reg.mhpmcounter6h;
                    when mhpmcounter7h_addr => csr_content_v := csr_reg.mhpmcounter7h;
                    when mhpmcounter8h_addr => csr_content_v := csr_reg.mhpmcounter8h;
                    when mhpmcounter9h_addr => csr_content_v := csr_reg.mhpmcounter9h;
                    when mstatus_addr => csr_content_v := csr_reg.mstatus;
                    when mie_addr => csr_content_v := csr_reg.mie;
                    when mtvec_addr => csr_content_v := csr_reg.mtvec;
                    when mcountinhibit_addr => csr_content_v := csr_reg.mcountinhibit;
                    when mscratch_addr => csr_content_v := csr_reg.mscratch;
                    when mepc_addr => csr_content_v := csr_reg.mepc;
                    when mcause_addr => csr_content_v := csr_reg.mcause;
                    when mtval_addr => csr_content_v := csr_reg.mtval;
                    when tselect_addr => csr_content_v := csr_reg.tselect;
                    when tdata1_addr => csr_content_v := csr_reg.tdata1;
                    when tdata2_addr => csr_content_v := csr_reg.tdata2;
                    when others => csr_content_v := (others => '-');
                end case;
                -- Do the operation
                -- Some bits should be ignored or hard wired to 0
                -- but we just ignore them
                case csr_access.op is
                    when csr_rw =>
                        csr_content_v := csr_access.dataout;
                    when csr_rs =>
                        csr_content_v := csr_content_v or csr_access.dataout;
                    when csr_rc =>
                        csr_content_v := csr_content_v and not csr_access.dataout;
                    when csr_rwi =>
                        csr_content_v(csr_content_v'left downto 5) := (others => '0');
                        csr_content_v(4 downto 0) := csr_access.immrs1;
                    when csr_rsi =>
                        csr_content_v(4 downto 0) := csr_content_v(4 downto 0) or csr_access.immrs1(4 downto 0);
                    when csr_rci =>
                        csr_content_v(4 downto 0) := csr_content_v(4 downto 0) and not csr_access.immrs1(4 downto 0);
                    when others =>
                        null;
                end case;
                -- Write back
                case csr_addr_v is
                    when mcycle_addr => csr_reg.mcycle <= csr_content_v;
                    when mcycleh_addr => csr_reg.mcycleh <= csr_content_v;
                    when minstret_addr => csr_reg.minstret <= csr_content_v;
                    when minstreth_addr => csr_reg.minstreth <= csr_content_v;
                    when mhpmevent3_addr => csr_reg.mhpmevent3 <= csr_content_v;
                    when mhpmevent4_addr => csr_reg.mhpmevent4 <= csr_content_v;
                    when mhpmevent5_addr => csr_reg.mhpmevent5 <= csr_content_v;
                    when mhpmevent6_addr => csr_reg.mhpmevent6 <= csr_content_v;
                    when mhpmevent7_addr => csr_reg.mhpmevent7 <= csr_content_v;
                    when mhpmevent8_addr => csr_reg.mhpmevent8 <= csr_content_v;
                    when mhpmevent9_addr => csr_reg.mhpmevent9 <= csr_content_v;
                    when mhpmcounter3_addr => csr_reg.mhpmcounter3 <= csr_content_v;
                    when mhpmcounter4_addr => csr_reg.mhpmcounter4 <= csr_content_v;
                    when mhpmcounter5_addr => csr_reg.mhpmcounter5 <= csr_content_v;
                    when mhpmcounter6_addr => csr_reg.mhpmcounter6 <= csr_content_v;
                    when mhpmcounter7_addr => csr_reg.mhpmcounter7 <= csr_content_v;
                    when mhpmcounter8_addr => csr_reg.mhpmcounter8 <= csr_content_v;
                    when mhpmcounter9_addr => csr_reg.mhpmcounter9 <= csr_content_v;
                    when mhpmcounter3h_addr => csr_reg.mhpmcounter3h <= csr_content_v;
                    when mhpmcounter4h_addr => csr_reg.mhpmcounter4h <= csr_content_v;
                    when mhpmcounter5h_addr => csr_reg.mhpmcounter5h <= csr_content_v;
                    when mhpmcounter6h_addr => csr_reg.mhpmcounter6h <= csr_content_v;
                    when mhpmcounter7h_addr => csr_reg.mhpmcounter7h <= csr_content_v;
                    when mhpmcounter8h_addr => csr_reg.mhpmcounter8h <= csr_content_v;
                    when mhpmcounter9h_addr => csr_reg.mhpmcounter9h <= csr_content_v;
                    when mstatus_addr => csr_reg.mstatus <= csr_content_v;
                    when mie_addr => csr_reg.mie <= csr_content_v;
                    when mtvec_addr => csr_reg.mtvec <= csr_content_v;
                    when mcountinhibit_addr => csr_reg.mcountinhibit <= csr_content_v;
                    when mscratch_addr => csr_reg.mscratch <= csr_content_v;
                    when mepc_addr => csr_reg.mepc <= csr_content_v;
                    when mcause_addr => csr_reg.mcause <= csr_content_v;
                    when mtval_addr => csr_reg.mtval <= csr_content_v;
                    when tdata1_addr => csr_reg.tdata1 <= csr_content_v;
                    when tdata2_addr => csr_reg.tdata2 <= csr_content_v;
                    when others => null;
                end case;
            end if;

            -- Set the cause for halting in DCSR
            -- cause(3) is load flag
            if csr_reg.dcsr_cause(3) = '1' and HAVE_OCD then
                csr_reg.dcsr(8 downto 6) <= csr_reg.dcsr_cause(2 downto 0);
                if csr_reg.dcsr_cause(2 downto 0) = "010" then
                    csr_reg.tdata1(22) <= '1';  -- hit0
                end if;
            end if;
            -- If a halt/break/step, load DPC with PC
            if control.load_dpc = '1' and HAVE_OCD then
                csr_reg.dpc <= id_ex.pc;
            end if;

            -- When we're in debug mode ...
            if control.indebug = '1' and I_dm_core_data_request.writecsr = '1' and HAVE_OCD then
                case csr_addr_v is
                    when mcycle_addr => csr_reg.mcycle <= I_dm_core_data_request.data;
                    when mcycleh_addr => csr_reg.mcycleh <= I_dm_core_data_request.data;
                    when minstret_addr => csr_reg.minstret <= I_dm_core_data_request.data;
                    when minstreth_addr => csr_reg.minstreth <= I_dm_core_data_request.data;
                    when mhpmevent3_addr => csr_reg.mhpmevent3 <= I_dm_core_data_request.data;
                    when mhpmevent4_addr => csr_reg.mhpmevent4 <= I_dm_core_data_request.data;
                    when mhpmevent5_addr => csr_reg.mhpmevent5 <= I_dm_core_data_request.data;
                    when mhpmevent6_addr => csr_reg.mhpmevent6 <= I_dm_core_data_request.data;
                    when mhpmevent7_addr => csr_reg.mhpmevent7 <= I_dm_core_data_request.data;
                    when mhpmevent8_addr => csr_reg.mhpmevent8 <= I_dm_core_data_request.data;
                    when mhpmevent9_addr => csr_reg.mhpmevent9 <= I_dm_core_data_request.data;
                    when mhpmcounter3_addr => csr_reg.mhpmcounter3 <= I_dm_core_data_request.data;
                    when mhpmcounter4_addr => csr_reg.mhpmcounter4 <= I_dm_core_data_request.data;
                    when mhpmcounter5_addr => csr_reg.mhpmcounter5 <= I_dm_core_data_request.data;
                    when mhpmcounter6_addr => csr_reg.mhpmcounter6 <= I_dm_core_data_request.data;
                    when mhpmcounter7_addr => csr_reg.mhpmcounter7 <= I_dm_core_data_request.data;
                    when mhpmcounter8_addr => csr_reg.mhpmcounter8 <= I_dm_core_data_request.data;
                    when mhpmcounter9_addr => csr_reg.mhpmcounter9 <= I_dm_core_data_request.data;
                    when mhpmcounter3h_addr => csr_reg.mhpmcounter3h <= I_dm_core_data_request.data;
                    when mhpmcounter4h_addr => csr_reg.mhpmcounter4h <= I_dm_core_data_request.data;
                    when mhpmcounter5h_addr => csr_reg.mhpmcounter5h <= I_dm_core_data_request.data;
                    when mhpmcounter6h_addr => csr_reg.mhpmcounter6h <= I_dm_core_data_request.data;
                    when mhpmcounter7h_addr => csr_reg.mhpmcounter7h <= I_dm_core_data_request.data;
                    when mhpmcounter8h_addr => csr_reg.mhpmcounter8h <= I_dm_core_data_request.data;
                    when mhpmcounter9h_addr => csr_reg.mhpmcounter9h <= I_dm_core_data_request.data;
                    when mstatus_addr => csr_reg.mstatus <= I_dm_core_data_request.data;
                    when mie_addr => csr_reg.mie <= I_dm_core_data_request.data;
                    when mtvec_addr => csr_reg.mtvec <= I_dm_core_data_request.data;
                    when mcountinhibit_addr => csr_reg.mcountinhibit <= I_dm_core_data_request.data;
                    when mscratch_addr => csr_reg.mscratch <= I_dm_core_data_request.data;
                    when mepc_addr => csr_reg.mepc <= I_dm_core_data_request.data;
                    when mcause_addr => csr_reg.mcause <= I_dm_core_data_request.data;
                    when mtval_addr => csr_reg.mtval <= I_dm_core_data_request.data;
                    when dcsr_addr => csr_reg.dcsr <= I_dm_core_data_request.data;
                    when dpc_addr => csr_reg.dpc <= I_dm_core_data_request.data;
                    when tdata1_addr => csr_reg.tdata1 <= I_dm_core_data_request.data;
                    when tdata2_addr => csr_reg.tdata2 <= I_dm_core_data_request.data;
                    when others => null;
                end case;
            end if;

            
            -- Set all bits hard to 0 except MTIE (7), MSIE (3)
            csr_reg.mie(csr_reg.mie'left downto 8) <= (others => '0');
            csr_reg.mie(6 downto 4) <= (others => '0');
            csr_reg.mie(2 downto 0) <= (others => '0');

            -- Set most bits of mstatus to 0
            csr_reg.mstatus(csr_reg.mstatus'left downto 13) <= (others => '0');
            csr_reg.mstatus(10 downto 8) <= (others => '0');
            csr_reg.mstatus(4 downto 4) <= (others => '0');
            csr_reg.mstatus(2 downto 0) <= (others => '0');
            
            -- Set most bits of mcountinhibit to 0
            if HAVE_ZIHPM then
                csr_reg.mcountinhibit(csr_reg.mcountinhibit'left downto 10) <= (others => '0');
            else
                csr_reg.mcountinhibit(csr_reg.mcountinhibit'left downto 3) <= (others => '0');
            end if;
            
            -- TI bit always 0
            csr_reg.mcountinhibit(1) <= '0';
            
            -- Bit 1 of mtvec should always be 0
            csr_reg.mtvec(1) <= '0';
            
            -- MCAUSE doesn't use that many bits...
            -- Only Interrupt Bit and 5 LSB are needed
            csr_reg.mcause(30 downto 5) <= (others => '0');

            -- Not al bits are used
            -- Only 40 bits are used in the counters
            -- There are only 6 events that can be counted
            if HAVE_ZIHPM then
                csr_reg.mhpmcounter3h(csr_reg.mhpmcounter3h'left downto 8) <= (others => '0');
                csr_reg.mhpmevent3(csr_reg.mhpmevent3'left downto 7) <= (others => '0');
                csr_reg.mhpmcounter4h(csr_reg.mhpmcounter3h'left downto 8) <= (others => '0');
                csr_reg.mhpmevent4(csr_reg.mhpmevent4'left downto 7) <= (others => '0');
                csr_reg.mhpmcounter5h(csr_reg.mhpmcounter5h'left downto 8) <= (others => '0');
                csr_reg.mhpmevent5(csr_reg.mhpmevent5'left downto 7) <= (others => '0');
                csr_reg.mhpmcounter6h(csr_reg.mhpmcounter6h'left downto 8) <= (others => '0');
                csr_reg.mhpmevent6(csr_reg.mhpmevent6'left downto 7) <= (others => '0');
                csr_reg.mhpmcounter7h(csr_reg.mhpmcounter7h'left downto 8) <= (others => '0');
                csr_reg.mhpmevent7(csr_reg.mhpmevent7'left downto 7) <= (others => '0');
                csr_reg.mhpmcounter8h(csr_reg.mhpmcounter8h'left downto 8) <= (others => '0');
                csr_reg.mhpmevent8(csr_reg.mhpmevent8'left downto 7) <= (others => '0');
                csr_reg.mhpmcounter9h(csr_reg.mhpmcounter9h'left downto 8) <= (others => '0');
                csr_reg.mhpmevent9(csr_reg.mhpmevent9'left downto 7) <= (others => '0');
            else
                csr_reg.mhpmcounter3 <= (others => '0');
                csr_reg.mhpmcounter3h <= (others => '0');
                csr_reg.mhpmevent3 <= (others => '0');
                csr_reg.mhpmcounter4 <= (others => '0');
                csr_reg.mhpmcounter4h <= (others => '0');
                csr_reg.mhpmevent4 <= (others => '0');
                csr_reg.mhpmcounter5 <= (others => '0');
                csr_reg.mhpmcounter5h <= (others => '0');
                csr_reg.mhpmevent5 <= (others => '0');
                csr_reg.mhpmcounter6 <= (others => '0');
                csr_reg.mhpmcounter6h <= (others => '0');
                csr_reg.mhpmevent6 <= (others => '0');
                csr_reg.mhpmcounter7 <= (others => '0');
                csr_reg.mhpmcounter7h <= (others => '0');
                csr_reg.mhpmevent7 <= (others => '0');
                csr_reg.mhpmcounter8 <= (others => '0');
                csr_reg.mhpmcounter8h <= (others => '0');
                csr_reg.mhpmevent8 <= (others => '0');
                csr_reg.mhpmcounter9 <= (others => '0');
                csr_reg.mhpmcounter9h <= (others => '0');
                csr_reg.mhpmevent9 <= (others => '0');
            end if;

            if HAVE_OCD then
                -- Debug registers
                csr_reg.dcsr(1 downto 0) <= "11";                -- Alwyas M-mode
                csr_reg.dcsr(3) <= '0';                          -- NMI interrupt pending not used
                csr_reg.dcsr(4) <= '0';                          -- mpriven not used
                csr_reg.dcsr(5) <= '0';                          -- v not used
                csr_reg.dcsr(9) <= '0';                          -- stoptime not used
                csr_reg.dcsr(10) <= '0';                         -- stopcount not used
                csr_reg.dcsr(11) <= '0';                         -- stepie not used
                csr_reg.dcsr(12) <= '0';                         -- ebreaku not used
                csr_reg.dcsr(13) <= '0';                         -- ebreaks not used
                csr_reg.dcsr(14) <= '0';                         -- reserved
                csr_reg.dcsr(16) <= '0';                         -- ebreakvu not used
                csr_reg.dcsr(17) <= '0';                         -- ebreakvs not used
                csr_reg.dcsr(27 downto 18) <= (others => '0');   -- reserved
                csr_reg.dcsr(31 downto 28) <= "0100";            -- version 1.0

                csr_reg.tdata1(31 downto 28) <= x"6";            -- always type 6 (mcontrol6)
                csr_reg.tdata1(26) <= '0';                       -- uncertain
                csr_reg.tdata1(25) <= '0';                       -- hit1 = 0
                csr_reg.tdata1(24) <= '0';                       -- vs
                csr_reg.tdata1(23) <= '0';                       -- vu
                csr_reg.tdata1(20) <= '0';                       -- 0
                csr_reg.tdata1(19) <= '0';                       -- 0
                csr_reg.tdata1(5) <= '0';                        -- uncertainen
                csr_reg.tdata1(4) <= '0';                        -- S mode
                csr_reg.tdata1(3) <= '0';                        -- U mode
                csr_reg.tdata1(1) <= '0';                        -- no store
                csr_reg.tdata1(0) <= '0';                        -- no load
                csr_reg.dpc(0) <= '0';                           -- LSB always 0
                csr_reg.tselect <= (others => '0');              -- Only 1 hw breakpoint
                -- Debug tinfo
                csr_reg.tinfo <= x"01000006";
            else
                csr_reg.dcsr <= (others => '0');
                csr_reg.dpc <= (others => '0');
                csr_reg.tdata1 <= (others => '0');
                csr_reg.tdata2 <= (others => '0');
                csr_reg.tinfo <= (others => '0');
                csr_reg.tselect <= (others => '0');
            end if;
            
            -- Interrupt handling takes priority over possible user
            -- update of the CSRs.
            -- The LIC checks if exceptions/interrupts are enabled.
            if control.trap_request = '1' and control.stall_on_trigger = '0' then
                -- Copy mie to mpie
                csr_reg.mstatus(7) <= csr_reg.mstatus(3);
                -- Set M mode
                csr_reg.mstatus(12 downto 11) <= "11";
                -- Disable interrupts
                csr_reg.mstatus(3) <= '0';
                -- Copy mcause
                csr_reg.mcause <= control.trap_mcause;
                -- Save PC at the point of interrupt
                csr_reg.mepc <= id_ex.pc;
                -- Set MTVAL
                if control.trap_mcause = x"00000000" then
                    -- Instruction misaligned fault, set MTVAL to all zeros
                    csr_reg.mtval <= (others => '0');
                elsif control.trap_mcause = x"00000001" then
                    -- Instruction access fault, set MTVAL to all zeros
                    csr_reg.mtval <= (others => '0');
                elsif control.trap_mcause = x"00000002" then
                    -- Illegal instruction fault, set MTVAL to all zeros
                    csr_reg.mtval <= (others => '0');
                elsif control.trap_mcause = x"00000003" then
                    -- Breakpoint, set MTVAL to all zeros
                    csr_reg.mtval <= (others => '0');
                else
                    -- Latch address from address bus
                    csr_reg.mtval <= csr_transfer.address_to_mtval;
                end if;
            elsif control.trap_release = '1' then
                -- Copy mpie to mie
                csr_reg.mstatus(3) <= csr_reg.mstatus(7);
                -- ??
                csr_reg.mstatus(7) <= '1';
                -- Keep M mode
                csr_reg.mstatus(12 downto 11) <= "11";
                -- mcause reset
                --csr_reg.mcause <= (others => '0');
                -- mepc reset
                --csr_reg.mepc <= (others => '0');
                -- mtval reset
                --csr_reg.mtval <= (others => '0');
            end if;
        end if;

        -- Calculate the MTVEC to be loaded in the PC on trap
        if VECTORED_MTVEC and csr_reg.mtvec(0) = '1' and csr_reg.mcause(31) = '1' then
            csr_transfer.mtvec_to_pc <= std_logic_vector(unsigned(csr_reg.mtvec(csr_reg.mtvec'left downto 2)) + unsigned(csr_reg.mcause(5 downto 0))) & "00";
        else
            csr_transfer.mtvec_to_pc <= csr_reg.mtvec(csr_reg.mtvec'left downto 2) & "00";
        end if;

        -- Low bit of mepc always 0, see priv ISA, S.3.1.14
        csr_reg.mepc(0) <= '0';
    end process;

    -- Transfer of MEPC to the PC
    csr_transfer.mepc_to_pc <= csr_reg.mepc;
    
    -- Hard wired CSR's
    csr_reg.mvendorid <= (others => '0'); --
    csr_reg.marchid <= (others => '0');
    csr_reg.mimpid <= std_logic_vector(to_unsigned(HW_VERSION, 32));
    csr_reg.mhartid <= (others => '0');
    csr_reg.mstatush <= (others => '0');
    csr_reg.mconfigptr <= (others => '0');
    csr_reg.misa(31 downto 13) <= x"4000" & "000";
    csr_reg.misa(12) <= '1' when HAVE_MULDIV else '0';
    csr_reg.misa(11 downto 0) <= x"100" when NUMBER_OF_REGISTERS = 32 else x"010";
    csr_reg.mip <= I_intrio;

    -- Custom read-only hardware description
    csr_reg.mxhw(0) <= '1'; --gpioa
    csr_reg.mxhw(1) <= '0'; --reserved
    csr_reg.mxhw(2) <= '0'; --reserved
    csr_reg.mxhw(3) <= '0'; --reserved
    csr_reg.mxhw(4) <= '1' when HAVE_UART1 else '0';
    csr_reg.mxhw(5) <= '0'; -- reserved
    csr_reg.mxhw(6) <= '1' when HAVE_I2C1 else '0';
    csr_reg.mxhw(7) <= '1' when HAVE_I2C2 else '0';
    csr_reg.mxhw(8) <= '1' when HAVE_SPI1 else '0';
    csr_reg.mxhw(9) <= '1' when HAVE_SPI2 else '0';
    csr_reg.mxhw(10) <= '1' when HAVE_TIMER1 else '0';
    csr_reg.mxhw(11) <= '1' when HAVE_TIMER2 else '0';
    csr_reg.mxhw(12) <= '0'; -- reserved
    csr_reg.mxhw(13) <= '0'; -- reserved
    csr_reg.mxhw(14) <= '0'; -- reserved
    csr_reg.mxhw(15) <= '1'; -- TIME/TIMEH
    csr_reg.mxhw(16) <= '1' when HAVE_MULDIV else '0';
    csr_reg.mxhw(17) <= '1' when FAST_DIVIDE and HAVE_MULDIV else '0';
    csr_reg.mxhw(18) <= '1' when HAVE_BOOTLOADER_ROM else '0';
    csr_reg.mxhw(19) <= '1' when HAVE_REGISTERS_IN_RAM else '0';
    csr_reg.mxhw(20) <= '1' when HAVE_ZBA else '0';
    csr_reg.mxhw(21) <= '1' when HAVE_FAST_STORE else '0';
    csr_reg.mxhw(22) <= '1' when HAVE_ZICOND else '0';
    csr_reg.mxhw(23) <= '1' when HAVE_ZBS else '0';
    csr_reg.mxhw(24) <= '1' when UART1_BREAK_RESETS else '0';
    csr_reg.mxhw(25) <= '1' when HAVE_WDT else '0';
    csr_reg.mxhw(26) <= '1' when HAVE_ZIHPM else '0';
    csr_reg.mxhw(27) <= '1' when HAVE_OCD else '0';
    csr_reg.mxhw(csr_reg.mxhw'left downto 28) <= (others => '0');

    -- Custom read-only synthesized clock frequency
    csr_reg.mxspeed <= std_logic_vector(to_unsigned(SYSTEM_FREQUENCY, 32));

    -- Copy system timer info
    csr_reg.mtime <= I_mtime;
    csr_reg.mtimeh <= I_mtimeh;

    
    --
    -- Local interrupt controller
    --

    -- The Local Interrupt Controller (LIC) determines which
    -- trap is to be served. Note that interrupts will only
    -- be served if the processor is in the exec state.
    -- Exceptions will be served in the exec en mem states,
    process (I_clk, I_areset, I_intrio, I_bus_response,
             I_instr_response.instr_access_error, control, csr_reg) is
    begin
        control.trap_request <= '0';
        control.trap_release <= '0';
        control.trap_mcause <= (others => '0');
        
        -- Priority as of Table 3.7 of "Volume II: RISC-V Privileged Architectures V20211203"
        -- Local hardware interrupts take priority over exceptions, the RISC-V system timer
        -- has the lowest hardware interrupt priority. Not all exceptions are implemented.
        -- Interrupts only when not stepping.
        -- NMI triggered by watchdog timeout, cannot be blocked, except by stepping.
        if I_intrio(31) = '1' and control.isstepping = '0' then
            control.trap_request <= '1';
            control.trap_mcause <= std_logic_vector(to_unsigned(31, control.trap_mcause'length));
            control.trap_mcause(31) <= '1';
        -- Currently unassigned
        elsif I_intrio(30) = '1' and csr_reg.mstatus(3) = '1' and control.may_interrupt ='1' and control.isstepping = '0' then
            control.trap_request <= '1';
            control.trap_mcause <= std_logic_vector(to_unsigned(30, control.trap_mcause'length));
            control.trap_mcause(31) <= '1';
        -- Currently unassigned
        elsif I_intrio(29) = '1' and csr_reg.mstatus(3) = '1' and control.may_interrupt ='1' and control.isstepping = '0' then
            control.trap_request <= '1';
            control.trap_mcause <= std_logic_vector(to_unsigned(29, control.trap_mcause'length));
            control.trap_mcause(31) <= '1';
        -- Currently unassigned
        elsif I_intrio(28) = '1' and csr_reg.mstatus(3) = '1' and control.may_interrupt ='1' and control.isstepping = '0' then
            control.trap_request <= '1';
            control.trap_mcause <= std_logic_vector(to_unsigned(28, control.trap_mcause'length));
            control.trap_mcause(31) <= '1';
        -- SPI1
        elsif I_intrio(27) = '1' and csr_reg.mstatus(3) = '1' and control.may_interrupt ='1' and control.isstepping = '0' then
            control.trap_request <= '1';
            control.trap_mcause <= std_logic_vector(to_unsigned(27, control.trap_mcause'length));
            control.trap_mcause(31) <= '1';
        -- I2C1
        elsif I_intrio(26) = '1' and csr_reg.mstatus(3) = '1' and control.may_interrupt ='1' and control.isstepping = '0' then
            control.trap_request <= '1';
            control.trap_mcause <= std_logic_vector(to_unsigned(26, control.trap_mcause'length));
            control.trap_mcause(31) <= '1';
        -- Currently unassigned
        elsif I_intrio(25) = '1' and csr_reg.mstatus(3) = '1' and control.may_interrupt ='1' and control.isstepping = '0' then
            control.trap_request <= '1';
            control.trap_mcause <= std_logic_vector(to_unsigned(25, control.trap_mcause'length));
            control.trap_mcause(31) <= '1';
        -- I2C2
        elsif I_intrio(24) = '1' and csr_reg.mstatus(3) = '1' and control.may_interrupt ='1' and control.isstepping = '0' then
            control.trap_request <= '1';
            control.trap_mcause <= std_logic_vector(to_unsigned(24, control.trap_mcause'length));
            control.trap_mcause(31) <= '1';
        -- UART1
        elsif I_intrio(23) = '1' and csr_reg.mstatus(3) = '1' and control.may_interrupt ='1' and control.isstepping = '0' then
            control.trap_request <= '1';
            control.trap_mcause <= std_logic_vector(to_unsigned(23, control.trap_mcause'length));
            control.trap_mcause(31) <= '1';
        -- Currently unassigned
        elsif I_intrio(22) = '1' and csr_reg.mstatus(3) = '1' and control.may_interrupt ='1' and control.isstepping = '0' then
            control.trap_request <= '1';
            control.trap_mcause <= std_logic_vector(to_unsigned(22, control.trap_mcause'length));
            control.trap_mcause(31) <= '1';
        -- TIMER2
        elsif I_intrio(21) = '1' and csr_reg.mstatus(3) = '1' and control.may_interrupt ='1' and control.isstepping = '0' then
            control.trap_request <= '1';
            control.trap_mcause <= std_logic_vector(to_unsigned(21, control.trap_mcause'length));
            control.trap_mcause(31) <= '1';
        -- TIMER1
        elsif I_intrio(20) = '1' and csr_reg.mstatus(3) = '1' and control.may_interrupt ='1' and control.isstepping = '0' then
            control.trap_request <= '1';
            control.trap_mcause <= std_logic_vector(to_unsigned(20, control.trap_mcause'length));
            control.trap_mcause(31) <= '1';
        -- Currently unassigned
        elsif I_intrio(19) = '1' and csr_reg.mstatus(3) = '1' and control.may_interrupt ='1' and control.isstepping = '0' then
            control.trap_request <= '1';
            control.trap_mcause <= std_logic_vector(to_unsigned(19, control.trap_mcause'length));
            control.trap_mcause(31) <= '1';
        -- EXTI
        elsif I_intrio(18) = '1' and csr_reg.mstatus(3) = '1' and control.may_interrupt ='1' and control.isstepping = '0' then
            control.trap_request <= '1';
            control.trap_mcause <= std_logic_vector(to_unsigned(18, control.trap_mcause'length));
            control.trap_mcause(31) <= '1';
        -- Currently unassigned
        elsif I_intrio(17) = '1' and csr_reg.mstatus(3) = '1' and control.may_interrupt ='1' and control.isstepping = '0' then
            control.trap_request <= '1';
            control.trap_mcause <= std_logic_vector(to_unsigned(17, control.trap_mcause'length));
            control.trap_mcause(31) <= '1';
        -- Currently unassigned
        elsif I_intrio(16) = '1' and csr_reg.mstatus(3) = '1' and control.may_interrupt ='1' and control.isstepping = '0' then
            control.trap_request <= '1';
            control.trap_mcause <= std_logic_vector(to_unsigned(16, control.trap_mcause'length));
            control.trap_mcause(31) <= '1';
        -- RISC-V machine software interrupt
        elsif I_intrio(3) = '1' and csr_reg.mstatus(3) = '1' and csr_reg.mie(3) = '1' and control.may_interrupt ='1' and control.isstepping = '0' then
            control.trap_request <= '1';
            control.trap_mcause <= std_logic_vector(to_unsigned(3, control.trap_mcause'length));
            control.trap_mcause(31) <= '1';
        -- RISC-V external timer interrupt
        elsif I_intrio(7) = '1' and csr_reg.mstatus(3) = '1' and csr_reg.mie(7) = '1' and control.may_interrupt ='1' and control.isstepping = '0' then
            control.trap_request <= '1';
            control.trap_mcause <= std_logic_vector(to_unsigned(7, control.trap_mcause'length));
            control.trap_mcause(31) <= '1';
        -- Exceptions from here. Can always start a trap.
        -- Instruction access from unimplemented ROM
        elsif control.instr_access_error(1) = '1' then
            control.trap_request <= '1';
            control.trap_mcause <= std_logic_vector(to_unsigned(1, control.trap_mcause'length));
        -- Illegal instruction, can also be a CSR instruction problem
        elsif control.illegal_instruction_decode = '1' or control.illegal_instruction_csr = '1' then
            control.trap_request <= '1';
            control.trap_mcause <= std_logic_vector(to_unsigned(2, control.trap_mcause'length));
        -- Instruction misaligned
        elsif control.instruction_misaligned = '1' then
            control.trap_request <= '1';
            control.trap_mcause <= std_logic_vector(to_unsigned(0, control.trap_mcause'length));
        -- ECALL instruction
        elsif control.ecall_request = '1' then
            control.trap_request <= '1';
            control.trap_mcause <= std_logic_vector(to_unsigned(11, control.trap_mcause'length));
        -- EBREAK instruction, Priv Spec if dcsr.EBREAKM is off
        elsif control.ebreak_request = '1' and csr_reg.dcsr(15) = '0' then
            control.trap_request <= '1';
            control.trap_mcause <= std_logic_vector(to_unsigned(3, control.trap_mcause'length));
        -- Load access error (inimplemented memory)
        elsif I_bus_response.load_access_error = '1' then
            control.trap_request <= '1';
            control.trap_mcause <= std_logic_vector(to_unsigned(5, control.trap_mcause'length));
        -- Store access error (inimplemented memory)
        elsif I_bus_response.store_access_error = '1' then
            control.trap_request <= '1';
            control.trap_mcause <= std_logic_vector(to_unsigned(7, control.trap_mcause'length));
        -- Load misaligned
        elsif I_bus_response.load_misaligned_error = '1' then
            control.trap_request <= '1';
            control.trap_mcause <= std_logic_vector(to_unsigned(4, control.trap_mcause'length));
        -- Store misaligned
        elsif I_bus_response.store_misaligned_error = '1' then
            control.trap_request <= '1';
            control.trap_mcause <= std_logic_vector(to_unsigned(6, control.trap_mcause'length));
        end if;
        control.trap_mcause(30 downto 5) <= (others => '0');

        -- Signal interrupt release
        if control.mret_request_delay = '1' then
            control.trap_release <= '1';
        end if;
    end process;

    -- Communication to and from DM
    O_dm_core_data_response.data <= csr_access.datain when I_dm_core_data_request.readcsr = '1' else
                                    data_from_gpr when I_dm_core_data_request.readgpr = '1' else
                                    I_bus_response.data when I_dm_core_data_request.readmem = '1' else
                                    x"00000000";

    O_dm_core_data_response.ack <= I_bus_response.ready;
    O_dm_core_data_response.buserr <= control.indebug and
                                      (I_bus_response.load_misaligned_error or I_bus_response.store_misaligned_error or
                                       I_bus_response.load_access_error or I_bus_response.store_access_error);
    O_dm_core_data_response.excep <= control.indebug and
                                     (control.illegal_instruction_csr or control.illegal_instruction_decode);

        
end architecture rtl;
