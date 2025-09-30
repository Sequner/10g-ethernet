module mac_top (
    /* --- MAC TX --- */
    input i_tx_clk,
    input i_tx_reset,
    input i_tx_clk_en,
    // Slave AXI-Stream Interface
    input  s_axis_tvalid,
    input  [N_SYMBOLS-1:0] s_axis_tkeep,
    input  [N_SYMBOLS-1:0][W_SYMBOL-1:0] s_axis_tdata,
    input  s_axis_tlast,
    output s_axis_tready,
    // Master XGMII Interface
    output [N_CHANNELS-1:0] o_tx_xgmii_ctrl,
    output [N_CHANNELS-1:0][W_BYTE-1:0] o_tx_xgmii_data,
    /* --- MAC RX --- */
    input i_rx_clk,
    input i_rx_reset,
    input i_rx_clk_en,
    // Master AXI-Stream Interface
    output m_axis_tvalid,
    output [N_SYMBOLS-1:0] m_axis_tkeep,
    output [N_SYMBOLS-1:0][W_SYMBOL-1:0] m_axis_tdata,
    output m_axis_tlast,
    output m_axis_tuser,
    // Slave XGMII Interface
    input [N_CHANNELS-1:0] i_rx_xgmii_ctrl,
    input [N_CHANNELS-1:0][W_BYTE-1:0] i_rx_xgmii_data
);

mac_tx_top u_mac_tx (
    .i_clk(i_tx_clk),
    .i_reset(i_tx_reset),
    .i_clk_en(i_tx_clk_en),
    .s_axis_tvalid(s_axis_tvalid),
    .s_axis_tkeep(s_axis_tkeep),
    .s_axis_tdata(s_axis_tdata),
    .s_axis_tlast(s_axis_tlast),
    .s_axis_tready(s_axis_tready),
    .o_xgmii_ctrl(o_tx_xgmii_ctrl),
    .o_xgmii_data(o_tx_xgmii_data)
);

mac_rx u_mac_rx (
    .i_clk(i_rx_clk),
    .i_reset(i_rx_reset),
    .i_clk_en(i_rx_clk_en),
    .i_xgmii_ctrl(i_rx_xgmii_ctrl),
    .i_xgmii_data(i_rx_xgmii_data),
    .m_axis_tvalid(m_axis_tvalid),
    .m_axis_tkeep(m_axis_tkeep),
    .m_axis_tdata(m_axis_tdata),
    .m_axis_tlast(m_axis_tlast),
    .m_axis_tuser(m_axis_tuser)
);
    
endmodule : mac_top