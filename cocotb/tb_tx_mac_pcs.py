import cocotb
from cocotb.triggers import Timer, RisingEdge
from cocotb.clock import Clock
from tb_env import *

CLK_PERIOD = 10

@cocotb.test()
async def test_basic_packet(dut):
    driver = AXISlaveDriver(dut, prefix="s")
    monitor = Monitor(dut, "o_pma_data")
    scoreboard = Scoreboard()

    cocotb.start_soon(Clock(dut.i_clk, CLK_PERIOD, units="ns").start())
    dut.s_tvalid.value = 0
    dut.s_tkeep.value = 0
    dut.s_tlast.value = 0
    dut.i_reset.value = 1
    await Timer(CLK_PERIOD*10)
    dut.i_reset.value = 0
    for _ in range(5):
        await RisingEdge(dut.i_clk)

    packet_data = [0xFFFFAAAA for _ in range(64)]
    packet_keep = [0xF for _ in range(64)]
    packet_keep[-1] = 3

    cocotb.start_soon(monitor.observe(80))
    await driver.send_packet(packet_data, packet_keep)
    await Timer(CLK_PERIOD*10)