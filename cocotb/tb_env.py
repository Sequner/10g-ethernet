import cocotb
from cocotb.triggers import RisingEdge
import random

class AXISlaveDriver:
    def __init__(self, dut, prefix="s_axis"):
        self.dut = dut
        self.tdata = getattr(dut, f"{prefix}_tdata")
        self.tkeep = getattr(dut, f"{prefix}_tkeep")
        self.tvalid = getattr(dut, f"{prefix}_tvalid")
        self.tready = getattr(dut, f"{prefix}_tready")
        self.tlast = getattr(dut, f"{prefix}_tlast")

    async def send_packet(self, data_list, keep_list):
        """Send a packet of bytes over AXI-Stream slave interface."""
        for i, val in enumerate(zip(data_list, keep_list)):
            self.tdata.value = val[0]
            self.tkeep.value = val[1]
            self.tvalid.value = 1
            self.tlast.value = 1 if i == len(data_list) - 1 else 0

            # Wait until DUT is ready
            while not self.tready.value:
                await RisingEdge(self.dut.i_clk)
            await RisingEdge(self.dut.i_clk)

        self.tvalid.value = 0
        self.tlast.value = 0

class Monitor:
    def __init__(self, dut, signal_name):
        self.dut = dut
        self.signal = getattr(dut, signal_name)
        self.captured = []

    async def observe(self, cycles=50):
        for _ in range(cycles):
            await RisingEdge(self.dut.i_clk)
            self.captured.append(int(self.signal.value))

class Scoreboard:
    def check(self, sent_data, received_data):
        expected = [x + 1 for x in sent_data]
        assert received_data[-len(sent_data):] == expected, \
            f"Scoreboard mismatch: got {received_data[-len(sent_data):]}, expected {expected}"