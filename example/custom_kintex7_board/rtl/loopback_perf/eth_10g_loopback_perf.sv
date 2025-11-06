module eth_10g_loopback_perf(
    // System clock
    input i_sys_clk,
    // Reference clock
    input i_mgtrefclk_p,
    input i_mgtrefclk_n
);

// Ethernet TX/RX clk
logic tx_clk;
logic rx_clk;
// VIO wires
logic vio_sys_reset;
logic [2:0] vio_sys_loopback;
logic vio_sys_rx_reset;
logic [9:0] vio_tx_packet_bytes;
// TX latency measurement wires
logic first_byte_sent;
logic [5:0] first_byte_latency;
// TX AXIS Driver
logic tx_m_axis_tvalid;
logic [3:0] tx_m_axis_tkeep;
logic [31:0] tx_m_axis_tdata;
logic tx_m_axis_tlast;
logic tx_m_axis_tready;
// RX AXIS Receiver
logic rx_s_axis_tvalid;
logic [3:0] rx_s_axis_tkeep;
logic [31:0] rx_s_axis_tdata;
logic rx_s_axis_tlast;
logic rx_s_axis_tuser;

// 2FF synchro
logic q_rx_byte_received, q_q_rx_byte_received;
logic q_rx_last_received, q_q_rx_last_received;
always_ff @(posedge tx_clk) begin
    q_rx_byte_received <= rx_s_axis_tvalid;
    q_q_rx_byte_received <= q_rx_byte_received;

    q_rx_last_received <= rx_s_axis_tlast & rx_s_axis_tvalid;
    q_q_rx_last_received <= q_rx_last_received;
end

sys_domain_vio u_sys_vio(
    .clk(i_sys_clk),
    .probe_out0(vio_sys_reset),
    .probe_out1(vio_sys_loopback)
);

tx_domain_vio u_tx_vio(
    .clk(tx_clk),
    .probe_out0(vio_tx_packet_bytes)
);

packet_sender u_packet_sender (
    .m_axis_clk(tx_clk),
    .m_axis_tready(tx_m_axis_tready),
    .m_axis_tvalid(tx_m_axis_tvalid),
    .m_axis_tkeep(tx_m_axis_tkeep),
    .m_axis_tdata(tx_m_axis_tdata),
    .m_axis_tlast(tx_m_axis_tlast),
    .i_vio_packet_bytes(vio_tx_packet_bytes),
    .i_sync_rx_last_received(q_q_rx_last_received),
    .o_first_byte_sent(first_byte_sent)
);


latency_counter u_latency_counter (
    .i_tx_clk(tx_clk),
    .i_first_byte_sent(first_byte_sent),
    .i_sync_byte_received(q_q_rx_byte_received),
    .o_first_byte_latency(first_byte_latency)
);

ethernet_10g u_ethernet (
    // System clock
    .i_sys_clk,
    .i_sys_reset(vio_sys_reset),
    // Reference clock
    .i_mgtrefclk_p,
    .i_mgtrefclk_n,
    // TX MAC-PCS clk
    .o_tx_clk(tx_clk),
    // TX gtx transceiver serial output
    .o_gtx_txp(),
    .o_gtx_txn(),
    // TX Slave AXI-Stream Interface
    .s_axis_tvalid(tx_m_axis_tvalid),
    .s_axis_tdata(tx_m_axis_tdata),
    .s_axis_tkeep(tx_m_axis_tkeep),
    .s_axis_tlast(tx_m_axis_tlast),
    .s_axis_tready(tx_m_axis_tready),
    // RX MAC-PCS clk
    .o_rx_clk(rx_clk),
    // RX gtx transceiver serial input
    .i_gtx_rxp('0),
    .i_gtx_rxn('0),
    // RX Master AXI-Stream Interface
    .m_axis_tvalid(rx_s_axis_tvalid),
    .m_axis_tkeep(rx_s_axis_tkeep),
    .m_axis_tdata(rx_s_axis_tdata),
    .m_axis_tlast(rx_s_axis_tlast),
    .m_axis_tuser(rx_s_axis_tuser),
    // Transceiver Loopback Mode
    // https://docs.amd.com/r/en-US/pg168-gtwizard/Loopback-Mode-Testing
    .i_gtx_loopback(vio_sys_loopback),
    // Transceiver RX Reset - for loopback
    .i_gtx_rx_reset()
);

tx_domain_ila u_tx_ila (
    .clk(tx_clk),
    .probe0(tx_m_axis_tvalid),
    .probe1(tx_m_axis_tkeep),
    .probe2(tx_m_axis_tdata),
    .probe3(tx_m_axis_tlast),
    .probe4(tx_m_axis_tready),
    .probe5(q_q_rx_byte_received),
    .probe6(first_byte_latency)
);

rx_domain_ila u_rx_ila (
    .clk(rx_clk),
    .probe0(rx_s_axis_tvalid),
    .probe1(rx_s_axis_tkeep),
    .probe2(rx_s_axis_tdata),
    .probe3(rx_s_axis_tlast),
    .probe4(rx_s_axis_tuser)
);

endmodule : eth_10g_loopback_perf