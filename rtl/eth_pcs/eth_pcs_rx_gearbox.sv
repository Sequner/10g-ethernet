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

// buffers
logic [W_DATA-1:0] q_data_buf; // data received in prev cycle
logic [W_SYNC-1:0] d_hdr_buf, q_hdr_buf; // hdr to be output
logic d_hdr_valid, q_hdr_valid;
// odd flag - header candidate is in odd bits of i_pma_data ([1,2] or [3,4] etc)
logic q_hdr_odd;
// block sync signals
logic slip;
// tracks which part of 64b block is being received
logic [W_TRANS_PER_BLK-1:0] q_trans_cnt;
// offset to obtain header
logic [W_RX_GEARBOX_OFFSET-1:0] d_hdr_offset, q_hdr_offset;
// offset to obtain data: uses header offset but lags it by 1 cycle
// because when header arrives only 1 portion of W_DATA width,
// another portion of data comes on the next cycle
// For example, i_pma_data = [H2, H1, D31, ... D2] - cycle 0
//              i_pma_data = [D1, D0, D31, ... D2] - cycle 1
//              i_pma_data = [D1, D0, H2, ...] -> header position changes
//                                                but we use the old hdr position
//                                                to get data properly 
logic [W_RX_GEARBOX_OFFSET-1:0] q_data_offset;
// clk_en: by default, hdr_valid is raised every 2 cycles for W_DATA=32 
// However, we need to skip one count when hdr is at offset 0
// because next 2 i_pma_data is gonna be fully data without headers.
// For  example, i_pma_data = [..., D0, H2, H1] - trans_id = 0
//               i_pma_data = [D31, ..., D0]    - trans_id = 1
//               i_pma_data = [D31, ..., D0]    - trans_id = 0 without clk_en
//                                                trans_id = 1 with clk_en
//                                                if trans_id = 0, it would check
//                                                wrong header position
logic d_clk_en;
logic q_clk_en = 1'b1;

always_comb begin : hdr_ctrl
    d_hdr_valid = (q_trans_cnt[W_TRANS_PER_BLK-1:0] == '0);
    if (q_hdr_odd) begin
        if (q_hdr_offset == W_DATA-2)
            d_hdr_buf = {q_data_buf[0], i_pma_data[q_hdr_offset+1]}; 
        else
            d_hdr_buf = {i_pma_data[q_hdr_offset+2], i_pma_data[q_hdr_offset+1]};
    end
    else
        d_hdr_buf = {i_pma_data[q_hdr_offset+1], i_pma_data[q_hdr_offset]};

    d_hdr_offset = q_hdr_offset;
    if (q_trans_cnt == '1 & !slip)
        d_hdr_offset -= 2'd2;
end

always_comb begin : output_ctrl
    o_grbx_hdr_valid = q_hdr_valid;
    o_grbx_hdr = q_hdr_buf;
    if (q_hdr_odd) begin
        // dynamic array slicing is not supported
        // o_grbx_data = {q_data_buf[q_data_offset:0], i_pma_data[W_DATA-1:q_data_offset+1]}
        for (int i=0; i<W_DATA; i++) begin
            if (i < W_DATA-(q_data_offset+1))
                o_grbx_data[i] = i_pma_data[i+(q_data_offset+1)];
            else
                o_grbx_data[i] = q_data_buf[i-(W_DATA-(q_data_offset+1))];
        end
    end
    else begin
        // dynamic array slicing is not supported
        // o_grbx_data = {q_data_buf[q_data_offset-1:0], i_pma_data[W_DATA-1:q_data_offset]}
        for (int i=0; i<W_DATA; i++) begin
            if (i < W_DATA-q_data_offset)
                o_grbx_data[i] = i_pma_data[i+q_data_offset];
            else
                o_grbx_data[i] = q_data_buf[i-(W_DATA-q_data_offset)];
        end
    end

    // at this point, all the data bits of the previous block were sent
    // and data bits of the new block are only starting on this cycle 
    // so there are no valid data bits being sent
    // hdr_odd == 1, cycle -1: [D30 ... D0 D31] - prev D31, current [D30:D0] sent,
    //               cycle  0: [D30 ... D0 H2 ] - prev D31, current [D30:D0] sent,
    //               cycle  1: [H1 D31 ... D1 ] - nothing sent(!!), [D31:D1] saved
    // hdr_odd == 0, cycle -1: [D31 ... D1 D0 ] - current [D31:D0] sent,
    //               cycle  0: [D31 ... D1 D0 ] - current [D31:D0] sent,
    //               cycle  1: [H2 H1 D31 ... D2] - nothing sent(!!) [D31:D2] saved
    o_grbx_data_valid = !(q_hdr_offset == W_DATA-2 & d_hdr_valid);
end

always_comb begin : clk_en_ctrl
    d_clk_en = 1'b1;
    if (q_clk_en) begin
        if (q_trans_cnt == 1'b1 & q_hdr_offset == '0)
            d_clk_en = '0;
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
    q_clk_en <= d_clk_en;
    q_data_buf <= i_pma_data;
    q_data_offset <= q_hdr_offset;
    q_hdr_valid <= d_hdr_valid;
    q_hdr_buf <= d_hdr_buf;
    q_hdr_odd <= (slip) ? ~q_hdr_odd : q_hdr_odd;
    if (d_clk_en) begin
        q_hdr_offset <= d_hdr_offset;
        q_trans_cnt <= (slip) ? '0 : q_trans_cnt + 1'b1;
    end
end

endmodule : eth_pcs_rx_gearbox