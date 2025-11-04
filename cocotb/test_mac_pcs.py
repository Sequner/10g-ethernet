import cocotb
from cocotb.triggers import Timer, RisingEdge
from cocotb.clock import Clock
import random
from tb_env import *

CLK_PERIOD = 10
N_TRANS = 32

@cocotb.test()
async def test_basic_packet(dut):
    # TX Driver
    driver = AXISSlaveDriver(dut)
    # AXI TX/RX Monitor
    s_monitor = AXISSlaveMonitor(dut)
    m_monitor = AXISMasterMonitor(dut)
    scoreboard = Scoreboard()

    cocotb.start_soon(Clock(dut.clk, CLK_PERIOD, units="ns").start())
    dut.s_axis_tvalid.value = 0
    dut.s_axis_tkeep.value = 0
    dut.s_axis_tlast.value = 0
    dut.reset.value = 1
    await Timer(CLK_PERIOD*5)
    dut.reset.value = 0
    await Timer(CLK_PERIOD*1000)
    for _ in range(5):
        await RisingEdge(dut.clk)

    packet_data = [random.randint(1, 1000) for _ in range(N_TRANS)]
    # range should have more than 62 bytes
    packet_keep = [0xF for _ in range(N_TRANS)]

    cocotb.start_soon(m_monitor.observe(5000))
    cocotb.start_soon(s_monitor.observe(5000))
    # set tkeep of last transaction all 1's
    packet_keep[-1] = 0xF
    await driver.send_packet(packet_data, packet_keep)
    # send same packet but with different tkeep 
    packet_keep[-1] = 0x7
    await driver.send_packet(packet_data, packet_keep)
    packet_keep[-1] = 0x3
    await driver.send_packet(packet_data, packet_keep)
    packet_keep[-1] = 0x1
    await driver.send_packet(packet_data, packet_keep)
    packet_keep[-1] = 0x0
    await driver.send_packet(packet_data, packet_keep)
    await Timer(CLK_PERIOD*100)
    scoreboard.check(s_monitor.captured, m_monitor.captured, \
                     m_monitor.captured_err_flag)
