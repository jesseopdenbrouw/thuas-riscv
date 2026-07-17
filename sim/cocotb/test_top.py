import logging
import cocotb
import time
from cocotb.triggers import Timer
from cocotb.triggers import ReadWrite
from cocotb.triggers import ReadOnly
from cocotb.triggers import RisingEdge
from cocotb.utils import get_sim_time
from cocotb.clock import Clock
from datetime import datetime

STEPS = 20000
LOGFILE = "driver.log"

# Need these to convert ordinal number to enumeration
STATE = ["boot0 ", "boot1 ", "exec  ", "mem   ", "flush ", "flush2", "md    ", "md2   ", "trap  ", "trap2 ", "trap3 ", "mret  ", "mret2 ", "wfi   ", "debug ", "debugflush", "debugflush2", "debugflush3"]

ALUOP = ["unknown", "nop", "add", "sub", "and", "or", "xor", "slt", "sltu", "addi", "andi", "ori", "xori", "slti", "sltiu", "sll", "srl", "sra", "slli", "srli", "srai", "lui", "auipc", "lw", "lh", "lhu", "lb", "lbu", "sw", "sh", "sb", "jal_jalr", "beq", "bne", "blt", "bge", "bltu", "bgeu", "trap", "mret", "multiply", "divrem", "csr", "sh1add", "sh2add", "sh3add", "bclr", "bclri", "bext", "bexti", "binv", "binvi", "bset", "bseti", "czeroeqz", "czeronez", "andn", "orn", "xnor", "clz", "ctz", "cpop", "max", "maxu", "min", "minu", "sextb", "sexth", "zexth", "rol", "ror", "rori", "orcb", "rev8", "mop", "pack", "packh", "brev8", "zip", "unzip"]


logger = logging.getLogger("my_test")
handler = logging.FileHandler(LOGFILE, mode="w")
logger.addHandler(handler)
logger.setLevel(logging.INFO)
logger.propagate = False

def convert(value, width):
    try:
        # Doesn't work with negative numbers
        x = "00000000000000000000" + str(hex(value))[2:]
    except:
        x = "????????????????????"

    x = x[-width:]
    return x

async def resetter(dut):
    """Resetter"""
    dut.I_areset.value = 0
    await Timer(105, unit="ns")
    dut.I_areset.value = 1
    
@cocotb.test()
async def test_top(dut):
    """THUAS RISC-V RV32 test."""

    # 50 MHz clock
    cocotb.start_soon(Clock(dut.I_clk, 20, unit="ns").start())
    cocotb.start_soon(resetter(dut))

    logger.info(f"Test started at {datetime.now()}")
    logger.info(f"{get_sim_time(unit='ns')} r={dut.I_areset.value} pc=0x{convert(dut.riscv0.core0.id_ex.pc.value,8)} in={convert(dut.riscv0.core0.id_ex.instr.value,8)} st={STATE[dut.riscv0.core0.control.state.value]} al={ALUOP[dut.riscv0.core0.id_ex.alu_op.value]}")
    await Timer(2, unit="ns")
    await ReadOnly()
    logger.info(f"{get_sim_time(unit='ns')} r={dut.I_areset.value} pc=0x{convert(dut.riscv0.core0.id_ex.pc.value,8)} in={convert(dut.riscv0.core0.id_ex.instr.value,8)} st={STATE[dut.riscv0.core0.control.state.value]} al={ALUOP[dut.riscv0.core0.id_ex.alu_op.value]}")

    for i in range(STEPS):
        await RisingEdge(dut.I_clk)
        await ReadOnly()
        logger.info(f"{get_sim_time(unit='ns')} r={dut.I_areset.value} pc=0x{convert(dut.riscv0.core0.id_ex.pc.value,8)} in={convert(dut.riscv0.core0.id_ex.instr.value,8)} st={STATE[dut.riscv0.core0.control.state.value]} al={ALUOP[dut.riscv0.core0.id_ex.alu_op.value]}")

    logger.info(f"Test completed at {datetime.now()}")
