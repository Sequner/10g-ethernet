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

`ifdef PMA_DATA_SHIFT
    localparam PMA_DATA_SHIFT = 1;
`else
    localparam PMA_DATA_SHIFT = 0;
`endif

logic [W_DATA+PMA_DATA_SHIFT-1:0] shifted_data;

always_ff @(posedge i_clk) begin : shift_ctrl
    shifted_data <= (shifted_data << W_DATA) + o_tx_pma_data;
end

assign i_rx_pma_data = shifted_data[W_DATA+PMA_DATA_SHIFT-1-:W_DATA]; // loopback

custom_mac_pcs u_eth_core(.*);

endmodule