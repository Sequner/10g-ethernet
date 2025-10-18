import cmn_params::*;
import eth_pcs_params::*;

module eth_pcs_tx_10g (
    input i_clk,
    input i_reset,
    input [N_CHANNELS-1:0] i_xgmii_ctrl,
    input [N_CHANNELS-1:0][W_BYTE-1:0] i_xgmii_data,
    output o_clk_en,
    output [W_DATA-1:0] o_pma_data
);

logic [W_TRANS_PER_BLK-1:0] trans_cnt;
logic [W_SYNC-1:0] sync_data;
logic [W_DATA-1:0] pld_data;
logic [W_DATA-1:0] scr_data;

eth_pcs_64_66_enc u_pcs_64_66_enc (
    .i_clk(i_clk),
    .i_reset(i_reset),
    .i_clk_en(o_clk_en),
    .i_trans_cnt(trans_cnt),
    .i_xgmii_ctrl(i_xgmii_ctrl),
    .i_xgmii_data(i_xgmii_data),
    .o_sync_data(sync_data),
    .o_pld_data(pld_data)
);

eth_pcs_scrambler #(
    .SCR_MODE(0),
    .SCR_BYPASS(0)
) 
u_pcs_scrambler (
    .i_clk(i_clk),
    .i_reset(i_reset),
    .i_clk_en(o_clk_en),
    .i_pld_data(pld_data),
    .o_scr_data(scr_data)
);

eth_pcs_tx_gearbox u_pcs_tx_gearbox (
    .i_clk(i_clk),
    .i_reset(i_reset),
    .i_sync_hdr(sync_data),
    .i_scr_data(scr_data),
    .o_clk_en(o_clk_en),
    .o_pma_data(o_pma_data),
    .o_trans_cnt(trans_cnt)
);
    
endmodule : eth_pcs_tx_10g