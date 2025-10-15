import cmn_params::*;
import eth_pcs_params::*;

module eth_pcs_rx_block_synch (
    input i_clk,
    input i_reset,
    input i_valid,
    input [W_SYNC-1:0] i_sync_hdr,
    output logic o_rx_lock,
    output logic o_slip
);

logic [W_SH_TH-1:0] d_sh_cnt, q_sh_cnt;
logic [W_SH_INVAL_TH-1:0] d_sh_inval_cnt, q_sh_inval_cnt;
logic d_blk_lock, q_blk_lock;
logic slip;
// for relaxing timing constraints
logic q_almost_sh_th, q_almost_sh_inval_th;
    
always_comb begin : header_cnt
    d_blk_lock = q_blk_lock;
    d_sh_cnt = q_sh_cnt + 1'b1;
    d_sh_inval_cnt = q_sh_inval_cnt;

    slip = '0;
    if (i_sync_hdr == SYNC_CTRL || i_sync_hdr == SYNC_DATA) begin
        if (q_almost_sh_th) begin
            d_sh_inval_cnt = '0;
            if (q_sh_inval_cnt == '0)
                d_blk_lock = 1'b1;
        end
    end
    else begin
        d_sh_inval_cnt += 1;
        if (q_almost_sh_inval_th | !q_blk_lock) begin
            slip = i_valid; // if hdr is valid, output 1
            d_blk_lock = '0;
            d_sh_cnt = '0;
        end
        else if (q_almost_sh_th) begin
            d_sh_inval_cnt = '0;
        end
    end
end

always_ff @(posedge i_clk) begin
    // having reset helps with timing.
    // for some reason, without it signals
    // are mapped to R pin of the flip-flop
    if (i_reset) begin
        q_sh_cnt <= '0;
        q_sh_inval_cnt <= '0;
        q_blk_lock <= '0;
    end
    else if (i_valid) begin
        q_sh_cnt <= d_sh_cnt;
        q_sh_inval_cnt <= d_sh_inval_cnt;
        q_blk_lock <= d_blk_lock;
        q_almost_sh_th <= (d_sh_cnt == SH_TH-1);
        q_almost_sh_inval_th <= (d_sh_inval_cnt == SH_INVAL_TH-1);
    end
end

assign o_slip = (i_valid) ? slip : '0;
assign o_rx_lock = q_blk_lock;

endmodule