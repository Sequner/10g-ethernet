import mac_params::*;

module custom_mac_pcs (
    // TX Clock & Reset
    input i_tx_clk,
    input i_tx_reset,
    // TX Slave AXI-Stream Interface
    input s_axis_tvalid,
    input [N_SYMBOLS-1:0][W_SYMBOL-1:0] s_axis_tdata,
    input [N_SYMBOLS-1:0] s_axis_tkeep,
    input s_axis_tlast,
    output s_axis_tready,
    // TX PMA
    output [W_DATA-1:0] o_tx_pma_data,
    // RX Clock & Reset
    input i_rx_clk,
    input i_rx_reset,
    // RX Master AXI-Stream Interface
    output m_axis_tvalid,
    output [N_SYMBOLS-1:0] m_axis_tkeep,
    output [N_SYMBOLS-1:0][W_SYMBOL-1:0] m_axis_tdata,
    output m_axis_tlast,
    output m_axis_tuser,
    // RX PMA Data
    input  [W_DATA-1:0] i_rx_pma_data
);

// TX wires 
logic tx_clk_en;
logic [N_CHANNELS-1:0] tx_xgmii_ctrl;
logic [N_CHANNELS-1:0][W_BYTE-1:0] tx_xgmii_data;
// RX wires 
logic rx_clk_en;
logic [N_CHANNELS-1:0] rx_xgmii_ctrl;
logic [N_CHANNELS-1:0][W_BYTE-1:0] rx_xgmii_data;

mac_top u_mac_top (
    .i_tx_clk,
    .i_tx_reset,
    .i_tx_clk_en(tx_clk_en),
    .s_axis_tvalid,
    .s_axis_tkeep,
    .s_axis_tdata,
    .s_axis_tlast,
    .s_axis_tready,
    .o_tx_xgmii_ctrl(tx_xgmii_ctrl),
    .o_tx_xgmii_data(tx_xgmii_data),
    .i_rx_clk,
    .i_rx_reset,
    .i_rx_clk_en(rx_clk_en),
    .m_axis_tvalid,
    .m_axis_tkeep,
    .m_axis_tdata,
    .m_axis_tlast,
    .m_axis_tuser,
    .i_rx_xgmii_ctrl(rx_xgmii_ctrl),
    .i_rx_xgmii_data(rx_xgmii_data)
);

eth_pcs_10g u_eth_pcs_top (
    .i_tx_clk,
    .i_tx_reset,
    .i_tx_xgmii_ctrl(tx_xgmii_ctrl),
    .i_tx_xgmii_data(tx_xgmii_data),
    .o_tx_clk_en(tx_clk_en),
    .o_tx_pma_data,
    .i_rx_clk,
    .i_rx_reset,
    .o_rx_clk_en(rx_clk_en),
    .o_rx_xgmii_ctrl(rx_xgmii_ctrl),
    .o_rx_xgmii_data(rx_xgmii_data),
    .i_rx_pma_data
);

endmodule : custom_mac_pcs