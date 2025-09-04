import cmn_params::*;
import eth_pcs_params::*;

module eth_pcs_tx_gearbox(
    input i_clk,
    input i_reset,
    input [W_SYNC-1:0] i_sync_data,
    input [W_DATA-1:0] i_scr_data,
    output o_clk_en,
    output [W_DATA-1:0] o_pma_data,
    output [W_TRANS_PER_BLK-1:0] o_trans_cnt
);

logic [W_TX_GEARBOX_CNT:0]   d_stop_cnt, q_stop_cnt;
logic [W_TX_GEARBOX_BUF-1:0] d_buf, q_buf;

always_comb begin : cnt_ctrl
    d_stop_cnt = q_stop_cnt;
    if (d_stop_cnt == TX_GEARBOX_CNT)
        d_stop_cnt = 0;
    else
        d_stop_cnt += 1;
end

// When new pcs block is generated, the gearbox
// receives W_DATA + 2 bits.
// Gearbox only sends W_DATA bits, so 2 additional
// bits are still left in the buffer.
// Since leftover bits are still there, we have to
// save the next portion of the block while accounting
// for those bits. The number of leftover bits
// increase until # of leftover == W_DATA.
// Then, clk_en is disabled, so that the gearbox
// clears the leftover bits.

// blk_cnt identifies how many pcs blocks were
// received so far. blk_cnt*2 is the offset of all
// leftover bits (2 bits per pcs block). 
always_comb begin : gearbox_buf_ctrl 
    integer blk_cnt, id;
    blk_cnt = q_stop_cnt[W_TX_GEARBOX_CNT:W_TRANS_PER_BLK];
    id = blk_cnt << 1;
    d_buf = q_buf >> W_DATA;
    // at trans_cnt 0, gearbox receives a new block
    // so we save W_DATA+W_SYNC bits
    if (o_trans_cnt == '0)
        d_buf[id+:(W_DATA+W_SYNC)] = {i_scr_data, i_sync_data};
    else
        d_buf[id+:W_DATA] = i_scr_data;
end

always_ff @(posedge i_clk) begin
    if (i_reset) begin
        q_stop_cnt <= '0;
        q_buf <= '0;
    end
    else begin
        q_stop_cnt <= d_stop_cnt;
        if (o_clk_en) begin
            q_buf <= d_buf;
        end
    end
end

assign o_clk_en = (q_stop_cnt != TX_GEARBOX_CNT);
assign o_pma_data = q_buf[W_DATA-1:0];
assign o_trans_cnt = q_stop_cnt[W_TRANS_PER_BLK-1:0];

endmodule : eth_pcs_tx_gearbox