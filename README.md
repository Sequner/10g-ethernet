# Low latency 10G-Base-R Ethernet

**32-bit 322 MHz MAC and Ethernet PCS design implemented for a custom Kintex-7 FPGA board from AliExpress :D**

## Example Design
The "Example" folder contains a fully functional 10G Ethernet core with MAC, PCS and PMA layers.

The 7-Series GTX transceiver functions as an Ethernet PMA module. TX/RX buffers and TX/RX gearboxes are disabled to minimize the transceiver latency.

The custom PCS module receives a raw PMA input and does block synchronization.

## Performance

Total latency from MAC TX input (AXI-Stream Slave) to MAC RX output (AXI-Stream Master) is **68 ns.**

## Design Details
Key design decisions:
1. MAC TX AXI-Stream Slave
    - For a valid transaction, all bytes of the input data must be valid (tkeep = '1), except when tlast is raised.
    - For tlast, the valid data bytes must be contiguously aligned.
      - For example, if there are 3 bytes being sent, tkeep[2:0] has to be raised, for 2 bytes, tkeep[1:0] and so on.
2. MAC RX AXI-Stream Master
    - For a valid transaction, not all the bytes of the output data can be valid. However, the data will still be aligned contiguously.
    - When tlast is raised, all frame data is received. If tuser is 1, if the error was detected in the frame, else there is no error.
3. RX-side 66B-to-64B decoder
    - The decoder does not follow the spec. The RX MAC layer adopts this change, and outputs data accordingly.
