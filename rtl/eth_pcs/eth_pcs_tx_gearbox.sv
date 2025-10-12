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

logic [W_TX_GEARBOX_CNT:0] d_stop_cnt;
logic [W_TX_GEARBOX_CNT:0] q_stop_cnt = '0;
logic [W_TX_GEARBOX_BUF-1:0] d_buf;
logic [W_TX_GEARBOX_BUF-1:0] q_buf = '0;

always_comb begin : cnt_ctrl
    d_stop_cnt = q_stop_cnt;
    if (q_stop_cnt == TX_GEARBOX_CNT)
        d_stop_cnt = '0;
    else
        d_stop_cnt += 1'b1;
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

// W_TX_GEARBOX_CNT:W_TRANS_PER_BLK shows the # of blocks
// received so far. Each received block adds up an offset
// of 2 bits because of sync hdr
integer id;

always_comb begin : gearbox_buf_ctrl 
    id = {q_stop_cnt[W_TX_GEARBOX_CNT:W_TRANS_PER_BLK], 1'b0};
    // The first W_DATA bits of q_buf are sent to PMA.
    // Hence, they are removed from the buffer
    d_buf = q_buf >> W_DATA;
    // at trans_cnt 0, gearbox receives a new block
    // so we save W_DATA+W_SYNC bits
    // at trans_cnt > 0 , id + 2 because once header + data 
    // were received, there are 2 more extra bits 
    if (o_trans_cnt == '0) // turn (H2, H1, D31...D0) into (D0...D31, H1, H2)
        d_buf[id+:(W_DATA+W_SYNC)] = concat_reverse(i_sync_data, i_scr_data); 
    else // reverse data
        d_buf[(id+2)+:W_DATA] = reverse(i_scr_data);
    // Note: reversing is done only for the sake of convenience during indexing
end

always_ff @(posedge i_clk) begin
    q_stop_cnt <= d_stop_cnt;
    q_buf <= d_buf;
end

assign o_clk_en = (q_stop_cnt < TX_GEARBOX_CNT);
// map (D0...D31, H1, H2) back to (H2, H1, D31...)
assign o_pma_data = reverse(q_buf[W_DATA-1:0]); 
assign o_trans_cnt = q_stop_cnt[W_TRANS_PER_BLK-1:0];

endmodule : eth_pcs_tx_gearbox