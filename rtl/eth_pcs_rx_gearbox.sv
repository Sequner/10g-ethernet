import cmn_params::*;
import eth_pcs_params::*;

module eth_pcs_rx_gearbox (
    input i_clk,
    input i_reset,
    input [W_DATA-1:0] i_pma_data,
    output logic o_grbx_hdr_valid,
    output logic [W_SYNC-1:0] o_grbx_hdr,
    output logic [W_DATA-1:0] o_grbx_data
);

// buffers
logic [W_DATA-1:0] q_data_buf; // data received in prev cycle
logic [W_SYNC-1:0] d_hdr_buf, q_hdr_buf; // hdr to be output
// odd flag - header is in odd bits of i_data ([1,2] or [3,4] etc)
logic d_hdr_odd, q_hdr_odd;
// block sync signals
logic lock, slip;

// offset consists of {blk cnt, trans id per 64b block}
// in case W_DATA=32, there are only 2 transactions per block
// so it's only 0 or 1.
// blk cnt shows how many blocks where received.
// since we are currently receiving 66b blocks, blk cnt is used
// to identify current location of header bits.
// hdr is 2 bits each, so shifting blk cnt << 1 will give the offset
// for hdr bits
logic [W_RX_GEARBOX_OFFSET-1:0] d_trans_cnt, q_trans_cnt;
logic [$clog2(W_DATA)-1:0] hdr_offset;
logic hdr_valid;

always_comb begin : hdr_ctrl
    d_hdr_valid = (q_trans_cnt[W_TRANS_PER_BLK-1:0] == '0);
    hdr_offset = {q_trans_cnt[W_RX_GEARBOX_OFFSET-1:W_TRANS_PER_BLK], 1'b0};
    if (q_hdr_odd) begin
        if (hdr_offset == '0)
            d_hdr_buf = {i_data[hdr_offset], q_data_buf[W_DATA-1]};        
        else
            d_hdr_buf = {i_data[hdr_offset], i_data[hdr_offset-1]};
    end
    else begin
        if (hdr_offset == '0)
            d_hdr_buf = {q_data_buf[W_DATA-1], q_data_buf[W_DATA-2]};
        else
            d_hdr_buf = {i_data[hdr_offset-1], i_data[hdr_offset-2]};
    end
end

always_comb begin : output_ctrl
    o_grbx_hdr_valid = q_hdr_valid;
    o_grbx_hdr = q_hdr_buf;
    if (q_hdr_odd)
        o_grbx_data = {i_data[hdr_offset:0], q_data_buf[W_DATA-1:hdr_offset+1]};
    else begin
        if (hdr_offset == '0)
            o_grbx_data = i_data;
        else 
            o_grbx_data = {i_data[hdr_offset-1:0], q_data_buf[W_DATA-1:hdr_offset]};
    end
end

eth_pcs_rx_block_synch u_sync(
    .i_clk(i_clk),
    .i_reset(i_reset),
    .i_valid(d_hdr_valid),
    .i_sync_hdr(d_hdr_buf),
    .o_slip(slip)
);

always_ff @(posedge i_clk) begin
    if (i_reset) begin
        q_trans_cnt <= '0;
        q_hdr_odd <= '0;
        q_hdr_valid <= '0;
        q_hdr_buf <= '0;
        q_data_buf <= '0;
    end
    else begin
        q_trans_cnt <= (slip) ? '0 : q_trans_cnt + 1'b1;
        q_hdr_odd <= (slip) ? ~q_hdr_odd : q_hdr_odd;
        q_hdr_valid <= d_hdr_valid;
        q_hdr_buf <= d_hdr_buf;
        q_data_buf <= d_data_buf;
    end
end

endmodule