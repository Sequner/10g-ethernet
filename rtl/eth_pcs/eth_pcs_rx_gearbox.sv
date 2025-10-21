import cmn_params::*;
import eth_pcs_params::*;

module eth_pcs_rx_gearbox (
    input i_clk,
    input i_reset,
    input [W_DATA-1:0] i_pma_data,
    output logic o_grbx_hdr_valid,
    output logic [W_SYNC-1:0] o_grbx_hdr,
    output logic o_grbx_data_valid,
    output logic [W_DATA-1:0] o_grbx_data
);

// Counter to disable clock
logic [W_RX_GEARBOX_CNT:0] d_stop_cnt, q_stop_cnt = '0;
// Tracks which part of 64b block is being received
logic [W_TRANS_PER_BLK-1:0] q_trans_cnt = '0;
// PMA data buffer - data received in prev cycle
logic [W_RX_GEARBOX_BUF-1:0] q_pma_data_buf = '0;
// Sync Header
logic [W_SYNC-1:0] d_hdr_buf, q_hdr_buf = '0; // hdr to be output
logic d_hdr_valid, q_hdr_valid = '0;
// Odd flag - header candidate is in odd bits of i_pma_data ([1,2] or [3,4] etc)
logic q_hdr_odd = '0;
logic [W_RX_GEARBOX_CNT:0] hdr_offset; // the location of the header
// Data offset - starting location of data bits
logic [W_RX_GEARBOX_CNT:0] q_data_offset = '0;
// hdr_skip: by default, hdr_valid is raised every 2 cycles for W_DATA=32.
// However, we need to skip one header when stop_cnt is at 32(W_DATA).
// For hdr_odd, at stop_cnt = 32, we receive        [H0  D63 D62 ... D32]
// at stop_cnt = 0, the second part hdr comes       [D30 D29 D28 ... H1 ] 
// So, hdr at stop_cnt = 32 is skipped because we do not get full hdr
logic hdr_skip;

// data_skip: by default, data is always sent without stop.
// However, we need to skip one data transaction when stop_cnt = 0.
// at stop_cnt = 31, we receive                     [D32 D31 D30 ... D2 ]
// at stop_cnt = 32, we receive                     [H1  H0  D63 ... D33]
// at stop_cnt = 0, we receive all 32 bits of data  [D31 D30 D29 ... D0 ]
// Note that at stop_cnt = 32, we output data [D63:D31], where
// D32 and D31 come from q_data_buf.
// However, at stop_cnt = 0, we receive [D31:D0] which we can output right
// away without accessing q_data_buf. Altough it is possible,
// at stop_cnt = 2, we will receive                 [D29 D28 ... H1  H0 ]
// We will have to skip sending data at this cycle and buffer [D29:D0].
// skipping data right after skipping header (stop_cnt = 32) is easier, 
// so instead of skipping at stop_cnt = 2, we skip at stop_cnt = 0.
logic q_data_skip = '0; // delayed hdr_skip 

// Block sync signal
logic slip;

always_comb begin : stop_cnt_ctrl
    d_stop_cnt = q_stop_cnt;
    // reset on slip
    if (q_stop_cnt == RX_GEARBOX_CNT | slip)
        d_stop_cnt = '0;
    else
        d_stop_cnt += 1'b1;
end

always_comb begin : hdr_ctrl
    hdr_skip    = (q_stop_cnt >= RX_GEARBOX_CNT);
    d_hdr_valid = (q_stop_cnt[W_TRANS_PER_BLK-1:0] == '0) & !hdr_skip;
    hdr_offset  = {q_stop_cnt[W_RX_GEARBOX_CNT:W_TRANS_PER_BLK], 1'b0};
    if (q_hdr_odd) begin
        // at hdr_offset 0, the header is located in the last bit
        // of the data received on the last cycle, and 
        // the first bit of the data received on this cycle 
        if (hdr_offset == '0)
            d_hdr_buf = {i_pma_data[hdr_offset], q_pma_data_buf[W_DATA-1]};
        else
            d_hdr_buf = {i_pma_data[hdr_offset], i_pma_data[hdr_offset-1]};
    end
    else begin
        if (hdr_offset == '0)
            d_hdr_buf = {q_pma_data_buf[W_DATA-1], q_pma_data_buf[W_DATA-2]};
        else
            d_hdr_buf = {i_pma_data[hdr_offset-1], i_pma_data[hdr_offset-2]};
    end
end

always_comb begin : output_ctrl
    o_grbx_hdr_valid = q_hdr_valid;
    o_grbx_hdr = q_hdr_buf;
    o_grbx_data_valid = !q_data_skip;
    if (q_hdr_odd) begin
        // dynamic array slicing is not supported
        // o_grbx_data = {i_pma_data[q_data_offset:0], q_pma_data_buf[W_DATA-1:q_data_offset+1]};
        for (int i=0; i<W_DATA; i++) begin
            if (i < W_DATA-(q_data_offset+1))
                o_grbx_data[i] = q_pma_data_buf[i+(q_data_offset+1)];
            else
                o_grbx_data[i] = i_pma_data[i-(W_DATA-(q_data_offset+1))];
        end
    end
    else begin
        // dynamic array slicing is not supported
        // o_grbx_data = {i_pma_buf[q_data_offset-1:0], q_pma_data_buf[W_DATA-1:q_data_offset]}
        for (int i=0; i<W_DATA; i++) begin
            if (i < W_DATA-q_data_offset)
                o_grbx_data[i] = q_pma_data_buf[i+q_data_offset];
            else
                o_grbx_data[i] = i_pma_data[i-(W_DATA-q_data_offset)];
        end
    end
end

eth_pcs_rx_block_synch u_sync(
    .i_clk(i_clk),
    .i_reset(i_reset),
    .i_valid(d_hdr_valid),
    .i_sync_hdr(d_hdr_buf),
    .o_rx_lock(),
    .o_slip(slip)
);

always_ff @(posedge i_clk) begin
    q_stop_cnt <= d_stop_cnt; // TODO: add reset if timing violation occurs
    q_pma_data_buf <= i_pma_data;
    q_hdr_valid <= d_hdr_valid;
    q_hdr_buf <= d_hdr_buf;
    q_hdr_odd <= (slip) ? ~q_hdr_odd : q_hdr_odd;
    q_data_skip <= hdr_skip;
    q_data_offset <= hdr_offset;
end

endmodule : eth_pcs_rx_gearbox