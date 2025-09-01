import cmn_params::*;
import eth_pcs_params::*;

module eth_pcs_rx_block_synch (
    input i_clk,
    input i_reset,
    input i_valid,
    input [W_SYNC-1:0] i_sync_hdr,
    output o_slip
);

logic [W_SH_VAL_TH-1:0] d_sh_cnt, q_sh_cnt;
logic [W_SH_INVAL_TH-1:0] d_sh_inval_cnt, q_sh_inval_cnt;
logic d_blk_lock, q_blk_lock;
    
always_comb begin : header_cnt
    d_blk_lock = q_blk_lock;

    d_sh_cnt = q_sh_cnt + 1'b1;
    d_sh_inval_cnt = q_sh_inval_cnt;
    
    if (i_sync_hdr == SYNC_CTRL || i_sync_hdr == SYNC_DATA) begin
        if (q_sh_cnt == SH_VAL_TH-1) begin
            if (q_sh_inval_cnt == '0)
                d_blk_lock = 1'b1;
            else
                d_sh_inval_cnt = '0;
        end
    end
    else begin
        d_sh_inval_cnt += 1;
        if ((q_sh_inval_cnt == SH_INVAL_TH-1) | !q_blk_lock) begin
            o_slip = 1'b1;
            d_blk_lock = '0;
            d_sh_cnt = '0;
        end
        else if (q_sh_cnt == SH_VAL_TH-1) begin
            d_sh_inval_cnt = '0;
        end
    end
end

always_ff @(posedge i_clk) begin
    if (i_reset) begin
        q_sh_cnt <= '0;
        q_sh_inval_cnt <= '0;
        q_blk_lock <= '0;
    end
    else if (i_valid) begin
        q_sh_cnt <= d_sh_cnt;
        q_sh_inval_cnt <= d_sh_inval_cnt;
        q_blk_lock <= d_blk_lock;
    end
end

endmodule