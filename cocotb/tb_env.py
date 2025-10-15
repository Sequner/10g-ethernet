import cocotb
from cocotb.triggers import RisingEdge
import random

class AXISSlaveDriver:
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
                await RisingEdge(self.dut.clk)
            await RisingEdge(self.dut.clk)

        self.tvalid.value = 0
        self.tlast.value = 0

class AXISSlaveMonitor:
    _signals = ["tvalid", "tdata", "tkeep", "tlast", "tready"]
    def __init__(self, dut, prefix='s_axis_'):
        self.dut = dut
        for sig in self._signals:
            name = prefix + sig
            setattr(self, sig, getattr(dut, name))
        self.captured = []

    async def observe(self, cycles=50):
        for _ in range(cycles):
            await RisingEdge(self.dut.clk)
            if not (self.tvalid.value == 1 and self.tready.value == 1):
                continue
            for i in range(len(self.tkeep)):
                if self.tkeep[i].value == 1:
                    self.captured.append(int(self.tdata[i].value))

class AXISMasterMonitor:
    _signals = ["tvalid", "tdata", "tkeep", "tlast", "tuser"]
    def __init__(self, dut, prefix='m_axis_'):
        self.dut = dut
        for sig in self._signals:
            name = prefix + sig
            setattr(self, sig, getattr(dut, name))
        self.captured = []
        self.captured_err_flag = 0

    async def observe(self, cycles=50):
        for _ in range(cycles):
            await RisingEdge(self.dut.clk)
            if self.tvalid.value == 0:
                continue
            for i in range(len(self.tkeep)):
                if self.tkeep[i].value == 1:
                    self.captured.append(int(self.tdata[i].value))
            # remove last 4, because they are CRC
            if self.tlast.value == 1:
                self.captured = self.captured[:-4]
                self.captured_err_flag = self.tuser.value

class Scoreboard:
    def check(self, sent_data, received_data, received_err_flag):
        assert received_err_flag == 0, \
            f"Transaction error flag raised"
        print(sent_data)
        assert sent_data == received_data, \
            f"Input&Output mismatch"