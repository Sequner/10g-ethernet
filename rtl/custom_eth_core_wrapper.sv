import cmn_params::*;
import mac_params::*;

module custom_eth_core_wrapper(
    input i_clk,
    input i_reset,
    input s_tvalid,
    input [N_SYMBOLS-1:0][W_SYMBOL-1:0] s_tdata,
    input [N_SYMBOLS-1:0] s_tkeep,
    input s_tlast,
    output s_tready,
    output [W_DATA-1:0] o_pma_data
);

logic [N_CHANNELS-1:0] xgmii_ctrl;
logic [N_CHANNELS-1:0][W_BYTE-1:0] xgmii_data;
logic clk_en;

mac_tx_top u_mac_tx_top(
    .i_clk(i_clk),
    .i_clk_en(clk_en), //TODO: apply normal clk_en
    .i_reset(i_reset),
    .s_tvalid(s_tvalid),
    .s_tdata(s_tdata),
    .s_tkeep(s_tkeep),
    .s_tlast(s_tlast),
    .s_tready(s_tready),
    .o_xgmii_ctrl(xgmii_ctrl),
    .o_xgmii_data(xgmii_data)
);

eth_pcs_tx_10g u_pcs_tx (
    .i_clk(i_clk),
    .i_reset(i_reset),
    .i_xgmii_ctrl(xgmii_ctrl),
    .i_xgmii_data(xgmii_data),
    .o_clk_en(clk_en),
    .o_pma_data(o_pma_data)
);

endmodule : custom_eth_core_wrapper