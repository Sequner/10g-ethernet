module eth_pcs_10g (
    input i_clk,
    input i_reset,
    /* --- PCS TX --- */
    input [N_CHANNELS-1:0] i_tx_xgmii_ctrl,
    input [N_CHANNELS-1:0][W_BYTE-1:0] i_tx_xgmii_data,
    output o_tx_clk_en,
    output [W_DATA-1:0] o_tx_pma_data,
    /* --- PCS RX --- */
    input [W_DATA-1:0] i_rx_pma_data,
    output o_rx_clk_en,
    output [N_CHANNELS-1:0] o_rx_xgmii_ctrl,
    output [N_CHANNELS-1:0][W_BYTE-1:0] o_rx_xgmii_data
);

eth_pcs_tx_10g u_pcs_tx (
    .i_clk(i_clk),
    .i_reset(i_reset),
    .i_xgmii_ctrl(i_tx_xgmii_ctrl),
    .i_xgmii_data(i_tx_xgmii_data),
    .o_clk_en(o_tx_clk_en),
    .o_pma_data(o_tx_pma_data)
);

eth_pcs_rx_10g u_pcs_rx (
    .i_clk(i_clk),
    .i_reset(i_reset),
    .i_pma_data(i_rx_pma_data),
    .o_clk_en(o_rx_clk_en),
    .o_xgmii_ctrl(o_rx_xgmii_ctrl),
    .o_xgmii_data(o_rx_xgmii_data)
);

endmodule : eth_pcs_10g