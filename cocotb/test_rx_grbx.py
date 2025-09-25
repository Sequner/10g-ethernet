import cocotb
from cocotb.triggers import Timer, RisingEdge
from cocotb.clock import Clock
from cocotb.types import LogicArray
from tb_env import *
from funcs import *

CLK_PERIOD = 10
W_DATA = 32
N_TRANS_PER_BLK = int(64/W_DATA)
OFFSET = 3

@cocotb.test()
async def test_basic(dut):
    cocotb.start_soon(Clock(dut.i_clk, CLK_PERIOD, units="ns").start())
    dut.i_pma_data.value = 0
    dut.i_reset.value = 1
    await Timer(CLK_PERIOD*10)
    dut.i_reset.value = 0
    for _ in range(5):
        await RisingEdge(dut.i_clk)
    data_66b = ([1, 0] + ([0]+[0]+[0]+[0])*16)*(2**10)
    for i in range(OFFSET):
        data_66b.pop()
        data_66b.insert(0, 1)
    scrambler(data_66b, OFFSET)
    out = []
    for i in range(int(len(data_66b)/W_DATA)):
        write = data_66b[i*W_DATA:(i+1)*W_DATA]
        dut.i_pma_data.value = LogicArray(write)
        await RisingEdge(dut.i_clk)
        if dut.u_sync.q_blk_lock.value and dut.o_grbx_data_valid.value:
            for bit in reversed(range(W_DATA)):
                out.append(dut.o_grbx_data[bit].value)
    
    hdr_removed = [bit for i, bit in enumerate(data_66b) if i%66!=OFFSET and i%66!=OFFSET+1]
    assert contains(out, hdr_removed), "Gearbox failed. Input/output mismatch"
    await Timer(CLK_PERIOD*10)