import cocotb
from cocotb.triggers import Timer, RisingEdge
from cocotb.clock import Clock
from cocotb.types import LogicArray
from tb_env import *
from funcs import *

CLK_PERIOD = 10
W_DATA = 32
N_TRANS_PER_BLK = int(64/W_DATA)

@cocotb.test()
async def test_basic(dut):
    cocotb.start_soon(Clock(dut.i_clk, CLK_PERIOD, units="ns").start())
    dut.i_pma_data.value = 0
    dut.i_reset.value = 1
    await Timer(CLK_PERIOD*10)
    dut.i_reset.value = 0
    for _ in range(5):
        await RisingEdge(dut.i_clk)

    data = [0]*66*4096
    scrambler(data)
    reverse_by_block(data)
    for i in range(int(len(data)/W_DATA)):
        dut.i_pma_data.value = LogicArray(data[i*W_DATA:(i+1)*W_DATA])
        await RisingEdge(dut.i_clk)
    await Timer(CLK_PERIOD*10)