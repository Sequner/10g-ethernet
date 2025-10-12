import cmn_params::*;
import eth_pcs_params::*;

module eth_pcs_66_64_decoder (
    input i_clk,
    input i_reset,
    input i_clk_en,
    input i_grbx_hdr_valid,
    input [W_SYNC-1:0] i_grbx_hdr,
    input [W_DATA-1:0] i_descr_data,
    output logic [N_CHANNELS-1:0] o_xgmii_ctrl,
    output logic [N_CHANNELS-1:0][W_BYTE-1:0] o_xgmii_data
);

// in case the initial parts of the block is receiverd
// assume the block is correct and send 1st half of data
// in case the last part of the block is received
// check if the block is correct, if not, send error
function automatic void decode_ctrl(
    input  [W_TRANS_PER_BLK-1:0] i_trans_cnt,
    input  [W_PLD_BLK-1:0] i_pld_blk,
    output [N_BYTES_PER_BLK-1:0] o_ctrl_blk,
    output [W_BLK-1:0] o_data_blk
);
    o_ctrl_blk = '1;
    o_data_blk = {8{SYM_ERR}};
    case (i_pld_blk[7:0])
        // CCCCCCCC
        C_TYPE: begin
            o_ctrl_blk = '1;
            if ((i_pld_blk[63:8] == {8{CODE_IDLE}}) | (i_trans_cnt != '1))
                o_data_blk = {8{SYM_IDLE}};
        end
        // SDDDDDDD
        S0_TYPE: begin
            o_ctrl_blk = 1'b1;
            o_data_blk[7:0] = SYM_START;
            o_data_blk[63:8] = i_pld_blk[63:8];
        end
        // CCCCSDDD
        S4_TYPE: begin
            if (i_pld_blk[35:8] == {4{CODE_IDLE}} | i_trans_cnt != '1) begin
                o_ctrl_blk = 8'h1F;
                o_data_blk[31:0]  = {4{SYM_IDLE}};
                o_data_blk[39:32] = SYM_START;
                o_data_blk[63:40] = i_pld_blk[63:40]; 
            end
        end
        // ODDDSDDD - O codes are ignored in this project, and replaced by errors
        // however, if they are used, change the implementation
        OS_TYPE: begin
            if (i_pld_blk[35:32] == '0 | i_trans_cnt != '1) begin
                o_ctrl_blk = 8'h1F;
                o_data_blk[39:32] = SYM_START;
                o_data_blk[63:40] = i_pld_blk[63:40]; 
            end
        end
        // TCCCCCCC
        T0_TYPE: begin
            if (i_pld_blk[63:15] == {7{CODE_IDLE}} | i_trans_cnt != '1) begin
                o_data_blk = {8{SYM_IDLE}};
                o_data_blk[31:24] = 8'h0; // 0 data bytes
            end
        end
        // Terminate type blocks are customized to reduce critical path
        // DTCCCCCC
        T1_TYPE: begin
            if (i_pld_blk[63:22] == {6{CODE_IDLE}} | i_trans_cnt != '1) begin
                o_ctrl_blk[0] = '0;
                o_data_blk = {8{SYM_IDLE}};
                o_data_blk[7:0] = i_pld_blk[15:8];
                o_data_blk[31:24] = 8'h1; // 1 data byte
            end
        end
        // DDTCCCCC
        T2_TYPE: begin
            if (i_pld_blk[63:29] == {5{CODE_IDLE}} | i_trans_cnt != '1) begin
                o_ctrl_blk[1:0] = '0;
                o_data_blk = {8{SYM_IDLE}};
                o_data_blk[15:0]  = i_pld_blk[23:8];
                o_data_blk[31:24] = 8'h2; // 2 data bytes
            end
        end
        // DDDTCCCC
        T3_TYPE: begin
            if (i_pld_blk[63:36] == {4{CODE_IDLE}} | i_trans_cnt != '1) begin
                o_ctrl_blk[2:0] = '0;
                o_data_blk = {8{SYM_IDLE}};
                o_data_blk[23:0] = i_pld_blk[31:8];
                o_data_blk[31:24] = 8'h3; // 3 data bytes
            end
        end
        // DDDDTCCC
        T4_TYPE: begin
            if (i_pld_blk[63:43] == {3{CODE_IDLE}} | i_trans_cnt != '1) begin
                o_ctrl_blk[2:0] = '0;
                o_ctrl_blk[4] = '0;
                o_data_blk = {8{SYM_IDLE}};
                o_data_blk[23:0] = i_pld_blk[31:8];
                o_data_blk[31:24] = 8'h4; // 4 data bytes
                o_data_blk[39:32] = i_pld_blk[39:32];
            end
        end
        // DDDDDTCC
        T5_TYPE: begin
            if (i_pld_blk[63:44] == {2{CODE_IDLE}} | i_trans_cnt != '1) begin
                o_ctrl_blk[2:0] = '0;
                o_ctrl_blk[5:4] = '0;
                o_data_blk = {8{SYM_IDLE}};
                o_data_blk[23:0] = i_pld_blk[31:8];
                o_data_blk[31:24] = 8'h5; // 5 data bytes
                o_data_blk[47:32] = i_pld_blk[47:32];
            end
        end
        // DDDDDDTC
        T6_TYPE: begin
            if (i_pld_blk[63:57] == {CODE_IDLE} | i_trans_cnt != '1) begin
                o_ctrl_blk[2:0] = '0;
                o_ctrl_blk[6:4] = '0;
                o_data_blk = {8{SYM_IDLE}};
                o_data_blk[23:0] = i_pld_blk[31:8];
                o_data_blk[31:24] = 8'h6; // 6 data bytes
                o_data_blk[55:32] = i_pld_blk[55:32];
            end
        end
        // DDDDDDDT
        T7_TYPE: begin
            if (i_pld_blk[63:36] == {4{CODE_IDLE}} | i_trans_cnt != '1) begin
                o_ctrl_blk[2:0] = '0;
                o_ctrl_blk[7:4] = '0;
                o_data_blk = {8{SYM_IDLE}};
                o_data_blk[23:0] = i_pld_blk[31:8];
                o_data_blk[31:24] = 8'h7; // 7 data bytes
                o_data_blk[63:32] = i_pld_blk[63:32];
            end
        end
        default: begin
            o_ctrl_blk = '1;
            o_data_blk = {8{SYM_ERR}};
        end
    endcase
endfunction

logic [W_TRANS_PER_BLK-1:0] d_trans_cnt, q_trans_cnt;
logic [N_TRANS_PER_BLK-1:0][W_DATA-1:0] d_pld_blk, q_pld_blk; // rolling data buffer
logic [W_SYNC-1:0] d_hdr, q_hdr; // buffered hdr

logic [N_TRANS_PER_BLK-1:0][N_CHANNELS-1:0] d_ctrl_blk, q_ctrl_blk;
logic [N_TRANS_PER_BLK-1:0][W_DATA-1:0] d_data_blk, q_data_blk;

always_comb begin : decoder_ctrl
    d_hdr = q_hdr;
    d_pld_blk = q_pld_blk;
    d_ctrl_blk = q_ctrl_blk;
    d_data_blk = q_data_blk;

    if (i_grbx_hdr_valid) begin // if hdr is valid, reset trans_cnt
        d_hdr = i_grbx_hdr;
        d_trans_cnt = '0;
    end
    else begin
        d_trans_cnt = q_trans_cnt + 1'b1;
    end

    d_pld_blk[d_trans_cnt] = i_descr_data;
    if (d_hdr == SYNC_DATA) begin
        d_ctrl_blk[d_trans_cnt] = '0;
        d_data_blk[d_trans_cnt] = i_descr_data;
    end
    else if (d_hdr == SYNC_CTRL) begin
        decode_ctrl(d_trans_cnt, d_pld_blk,
                    d_ctrl_blk,  d_data_blk);
    end
    else begin // error block in case incorrect header is received
        d_ctrl_blk = '1;
        d_data_blk = {8{SYM_ERR}};
    end
end

always_ff @(posedge i_clk) begin : ff_ctrl
    if (i_clk_en) begin
        q_trans_cnt <= d_trans_cnt;
        q_hdr <= d_hdr;
        q_pld_blk  <= d_pld_blk;
        q_ctrl_blk <= d_ctrl_blk;
        q_data_blk <= d_data_blk;
    end
end

assign o_xgmii_ctrl = q_ctrl_blk[q_trans_cnt];
assign o_xgmii_data = q_data_blk[q_trans_cnt];
    
endmodule : eth_pcs_66_64_decoder