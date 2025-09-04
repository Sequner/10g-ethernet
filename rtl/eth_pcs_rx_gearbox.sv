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
logic d_hdr_valid, q_hdr_valid;
// odd flag - header candidate is in odd bits of i_pma_data ([1,2] or [3,4] etc)
logic q_hdr_odd;
// block sync signals
logic slip;
logic [W_TRANS_PER_BLK-1:0] q_trans_cnt;
logic [W_RX_GEARBOX_OFFSET-1:0] d_hdr_offset, q_hdr_offset;
// cnt_skip: by default, hdr_valid is raised every 2 cycles for W_DATA=32 
// However, we need to skip one count when hdr is at i_pma_data[1:0]
// because next 2 i_pma_data is gonna be fully data without headers.
logic d_clk_en, q_clk_en;

always_comb begin : hdr_ctrl
    d_hdr_valid = (q_trans_cnt[W_TRANS_PER_BLK-1:0] == '0);
    if (q_hdr_odd) begin
        if (q_hdr_offset == '0)
            d_hdr_buf = {q_data_buf[q_hdr_offset], i_pma_data[W_DATA-1]}; 
        else
            d_hdr_buf = {i_pma_data[q_hdr_offset], i_pma_data[q_hdr_offset-1]};
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
        // o_grbx_data = {q_data_buf[W_DATA-1-(q_hdr_offset+1):0], 
        //                i_pma_data[W_DATA-1:W_DATA-1-q_hdr_offset]}
        for (int i=0; i<W_DATA; i++) begin
            if (i < q_hdr_offset+1)
                o_grbx_data[i] = i_pma_data[i+q_hdr_offset];
            else
                o_grbx_data[i] = q_data_buf[i-(q_hdr_offset+1)];
        end
    end
    else begin
        if (q_hdr_offset == '0)
            o_grbx_data = i_pma_data;
        else begin
            // dynamic array slicing is not supported
            // o_grbx_data = {q_data_buf[q_hdr_offset-1:0], i_pma_data[W_DATA-1:q_hdr_offset]}
            for (int i=0; i<W_DATA; i++) begin
                if (i < (W_DATA-1-q_hdr_offset)+1)
                    o_grbx_data[i] = i_pma_data[i+q_hdr_offset];
                else
                    o_grbx_data[i] = q_data_buf[i-((W_DATA-1-q_hdr_offset)+1)];
            end
        end
    end
end

always_comb begin : clk_en_ctrl
    d_clk_en = 1'b1;
    if (q_clk_en) begin
        if (q_hdr_odd & q_trans_cnt == 1'b1 & q_hdr_offset == 2'd2)
            d_clk_en = '0;
        else if (!q_hdr_odd & q_trans_cnt == 1'b1 & q_hdr_offset == 2'd0)
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
    if (i_reset) begin
        q_hdr_odd <= '0;
        q_hdr_offset <= '0;
        q_hdr_valid <= '0;
        q_hdr_buf <= '0;
        q_data_buf <= '0;
        q_trans_cnt <= '0;
    end
    else if (d_clk_en) begin
        q_hdr_odd <= (slip) ? ~q_hdr_odd : q_hdr_odd;
        q_hdr_offset <= d_hdr_offset;
        q_hdr_valid <= d_hdr_valid;
        q_hdr_buf <= d_hdr_buf;
        q_data_buf <= i_pma_data;
        q_trans_cnt <= (slip) ? '0 : q_trans_cnt + 1'b1;
    end

    q_clk_en <= d_clk_en;
end

endmodule