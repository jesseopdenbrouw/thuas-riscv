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

SIMTIME = 20 # in milliseconds
STEPS = (int)(SIMTIME*1000000/20)
LOGFILE = "address.csv"

# Need these to convert ordinal number to enumeration
STATE = ["boot0 ", "boot1 ", "exec  ", "mem   ", "flush ", "flush2", "md    ", "md2   ", "trap  ", "trap2 ", "trap3 ", "mret  ", "mret2 ", "wfi   ", "debug ", "debugflush", "debugflush2", "debugflush3"]

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

    logger.info(f"# Test started at {datetime.now()}")
    await Timer(20, unit="ns")
    await ReadOnly()

    for i in range(STEPS):
        await RisingEdge(dut.I_clk)
        await ReadOnly()
        if dut.riscv0.core0.control.state.value == 2: # 2 == exec state
            logger.info(f"{get_sim_time(unit='ns')};{dut.riscv0.core0.id_ex.pc.value.to_unsigned()}")

    logger.info(f"# Test completed at {datetime.now()}")
