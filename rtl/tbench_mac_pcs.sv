module tbench_mac_pcs;

import cmn_params::*;
import mac_params::*;
import eth_pcs_params::*;

logic i_clk;
logic i_reset;
logic s_axis_tvalid;
logic [N_SYMBOLS-1:0][W_SYMBOL-1:0] s_axis_tdata;
logic [N_SYMBOLS-1:0] s_axis_tkeep;
logic s_axis_tlast;
logic s_axis_tready;
logic m_axis_tvalid;
logic [N_SYMBOLS-1:0] m_axis_tkeep;
logic [N_SYMBOLS-1:0][W_SYMBOL-1:0] m_axis_tdata;
logic m_axis_tlast;
logic m_axis_tuser;
logic [W_DATA-1:0] o_tx_pma_data;
logic [W_DATA-1:0] i_rx_pma_data;

assign i_rx_pma_data = o_tx_pma_data; // loopback

custom_mac_pcs u_eth_core(.*);

endmodule