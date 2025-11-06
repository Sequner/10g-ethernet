import cmn_params::*;
import eth_pcs_params::*;

module eth_pcs_tx_gearbox(
    input i_clk,
    input i_reset,
    input [W_SYNC-1:0] i_sync_hdr,
    input [W_DATA-1:0] i_scr_data,
    output o_clk_en,
    output [W_DATA-1:0] o_pma_data,
    output [W_TRANS_PER_BLK-1:0] o_trans_cnt
);

logic [W_TX_GEARBOX_CNT:0] d_stop_cnt;
logic [W_TX_GEARBOX_CNT:0] q_stop_cnt = '0;
logic [W_TX_GEARBOX_CNT:0] hdr_offset;
logic [W_TX_GEARBOX_CNT:0] d_data_offset;
logic [W_TX_GEARBOX_CNT:0] q_data_offset = 2'd2;
logic [W_TX_GEARBOX_BUF-1:0] d_buf;
logic [W_TX_GEARBOX_BUF-1:0] q_buf = '0;

always_comb begin : cnt_ctrl
    d_stop_cnt = q_stop_cnt;
    if (q_stop_cnt >= TX_GEARBOX_CNT)
        d_stop_cnt = '0;
    else
        d_stop_cnt += 1'b1;
    
    d_data_offset = q_data_offset;
    if (q_stop_cnt == TX_GEARBOX_CNT)
        d_data_offset = 2'd2;
    // at trans_cnt == '0, we receive a sync header
    else if (o_trans_cnt == '1)
        d_data_offset += 2'd2;
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

// Buff state:
// Bit pos  -  63  62  61  ... 33  32  31  30  ... 2   1   0  
// Cycle 0  - [X   X   X   ... D31 D30 D29 D28 ... D0  H1  H0 ]
// Cycle 1  - [X   X   X   ... D63 D62 D61 D60 ... D32 D31 D30]
// Cycle 2  - [X   X   X   ... D29 D28 D27 D26 ... H0 D63 D62 ]
// ...
// Cycle 31 - [D63 D62 D61 ... D33 D32 D31 D30 ... D2  D1  D0 ]
// Cycle 32 - [X   X   X   ... X   X   D63 D62 ... D34 D33 D32]
// No new data comes at cycle 32 because clk_en is 0

// W_TX_GEARBOX_CNT:W_TRANS_PER_BLK shows the # of blocks
// received so far. Each received block adds up an offset
// of 2 bits because of sync hdr
integer id;

always_comb begin : gearbox_buf_ctrl 
    hdr_offset = {q_stop_cnt[W_TX_GEARBOX_CNT-1:W_TRANS_PER_BLK], 
                  {W_TRANS_PER_BLK{1'b0}}};
//    id = {q_stop_cnt[W_TX_GEARBOX_CNT-1:W_TRANS_PER_BLK], 1'b0};
    // The first W_DATA bits of q_buf are sent to PMA.
    // Hence, they are removed from the buffer
    d_buf = {'0, q_buf[W_TX_GEARBOX_BUF-1:W_DATA]};
    // at trans_cnt 0, gearbox receives a new block
    // so we save W_DATA+W_SYNC bits
    // at trans_cnt > 0 , id + 2 because once header + data 
    // were received, there are 2 more extra bits 
    // when o_clk_en is 0, the incoming data should be skipped
    if (o_clk_en) begin
        if (o_trans_cnt == '0)
            d_buf[hdr_offset+:W_SYNC] = i_sync_hdr; 
        d_buf[q_data_offset+:W_DATA] = i_scr_data;
    end
end

always_ff @(posedge i_clk) begin
    q_stop_cnt <= d_stop_cnt;
    q_buf <= d_buf;
    q_data_offset <= d_data_offset;
end

assign o_clk_en = (q_stop_cnt < TX_GEARBOX_CNT);
// Always output first W_DATA bits
assign o_pma_data = d_buf[W_DATA-1:0]; 
assign o_trans_cnt = q_stop_cnt[W_TRANS_PER_BLK-1:0];

endmodule : eth_pcs_tx_gearbox