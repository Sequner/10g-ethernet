import cmn_params::*;
import eth_pcs_params::*;

module eth_pcs_64_66_enc(
    input i_clk,
    input i_reset,
    input i_clk_en,
    input [W_TRANS_PER_BLK-1:0] i_trans_cnt,
    input logic [N_CHANNELS-1:0] i_xgmii_ctrl,
    input logic [N_CHANNELS-1:0][W_BYTE-1:0] i_xgmii_data,
    output logic [W_SYNC-1:0] o_sync_data,
    output logic [W_DATA-1:0] o_pld_data
);

// Blocks types are based on
// Section 49.2.13.2.3 of the spec 
// No /O/ and /LI/ support
function automatic is_data_block(
    input logic [N_BYTES_PER_BLK-1:0] i_ctrl
);
    is_data_block = (i_ctrl == '0);
endfunction

// Eight valid ctrl characters
// other than /O/, /S/, /T/, /LI/, and /E/
// CCCCCCCC
function automatic is_c_block(
    input logic [N_BYTES_PER_BLK-1:0] i_ctrl,
    input logic [N_BYTES_PER_BLK-1:0][W_BYTE-1:0] i_data
);
    is_c_block = 1'b0;
    if (i_ctrl == 8'b11111111 & i_data[0] == SYM_IDLE)
        is_c_block = 1'b1;
endfunction

// Start character on 0th or 4th byte
// If start on 0th, others must be data
// SDDDDDDD 
function automatic is_s0_block(
    input logic [N_BYTES_PER_BLK-1:0] i_ctrl,
    input logic [N_BYTES_PER_BLK-1:0][W_BYTE-1:0] i_data
);
    is_s0_block = 1'b0;
    if (i_ctrl == 8'b00000001 & i_data[0] == SYM_START) 
        is_s0_block = 1'b1;
endfunction

// If start on 4th, 0-3rd must be IDLE
// CCCCSDDD
function automatic is_s4_block(
    input logic [N_BYTES_PER_BLK-1:0] i_ctrl,
    input logic [N_BYTES_PER_BLK-1:0][W_BYTE-1:0] i_data
);
    is_s4_block = 1'b0;
    if (i_ctrl == 8'b00011111 & i_data[4] == SYM_START) 
        is_s4_block = 1'b1;
endfunction

// Termination character on 0th byte
// the rest is IDLE
// TCCCCCCC
function automatic is_t0_block(
    input logic [N_BYTES_PER_BLK-1:0] i_ctrl,
    input logic [N_BYTES_PER_BLK-1:0][W_BYTE-1:0] i_data
);
    is_t0_block = 1'b0;
    if (i_ctrl == 8'b11111111 & i_data[0] == SYM_TERM)
        is_t0_block = 1'b1;
endfunction

// Termination character on 1st byte
// 0th byte is data, the rest is IDLE
// DTCCCCCC
function automatic is_t1_block(
    input logic [N_BYTES_PER_BLK-1:0] i_ctrl,
    input logic [N_BYTES_PER_BLK-1:0][W_BYTE-1:0] i_data
);
    is_t1_block = 1'b0;
    if (i_ctrl == 8'b11111110 & i_data[1] == SYM_TERM)
        is_t1_block = 1'b1;
endfunction

// Termination character on 2nd byte,
// bytes 0 and 1 are data, the rest is IDLE
// DDTCCCCC
function automatic is_t2_block(
    input logic [N_BYTES_PER_BLK-1:0] i_ctrl,
    input logic [N_BYTES_PER_BLK-1:0][W_BYTE-1:0] i_data
);
    is_t2_block = 1'b0;
    if (i_ctrl == 8'b11111100 & i_data[2] == SYM_TERM)
        is_t2_block = 1'b1;
endfunction

// Termination character on 3rd byte,
// bytes 0 to 2 are data, the rest is IDLE
// DDDTCCCC
function automatic is_t3_block(
    input logic [N_BYTES_PER_BLK-1:0] i_ctrl,
    input logic [N_BYTES_PER_BLK-1:0][W_BYTE-1:0] i_data
);
    is_t3_block = 1'b0;
    if (i_ctrl == 8'b11111000 & i_data[3] == SYM_TERM)
        is_t3_block = 1'b1;
endfunction

// Termination character on 4th byte,
// bytes 0 to 3 are data, the rest is IDLE
// DDDDTCCC
function automatic is_t4_block(
    input logic [N_BYTES_PER_BLK-1:0] i_ctrl,
    input logic [N_BYTES_PER_BLK-1:0][W_BYTE-1:0] i_data
);
    is_t4_block = 1'b0;
    if (i_ctrl == 8'b11110000 & i_data[4] == SYM_TERM)
        is_t4_block = 1'b1;
endfunction

// Termination character on 5th byte,
// bytes 0 to 4 are data, the rest is IDLE
// DDDDDTCCC
function automatic is_t5_block(
    input logic [N_BYTES_PER_BLK-1:0] i_ctrl,
    input logic [N_BYTES_PER_BLK-1:0][W_BYTE-1:0] i_data
);
    is_t5_block = 1'b0;
    if (i_ctrl == 8'b11100000 & i_data[5] == SYM_TERM)
        is_t5_block = 1'b1;
endfunction

// Termination character on 6th byte,
// bytes 0 to 5 are data, the rest is IDLE
// DDDDDDTC
function automatic is_t6_block(
    input logic [N_BYTES_PER_BLK-1:0] i_ctrl,
    input logic [N_BYTES_PER_BLK-1:0][W_BYTE-1:0] i_data
);
    is_t6_block = 1'b0;
    if (i_ctrl == 8'b11000000 & i_data[6] == SYM_TERM)
        is_t6_block = 1'b1;
endfunction

// Termination character on 7th byte,
// the rest are data 
// DDDDDDDT
function automatic is_t7_block(
    input logic [N_BYTES_PER_BLK-1:0] i_ctrl,
    input logic [N_BYTES_PER_BLK-1:0][W_BYTE-1:0] i_data
);
    is_t7_block = 1'b0;
    if (i_ctrl == 8'b10000000 & i_data[7] == SYM_TERM)
        is_t7_block = 1'b1;
endfunction

function automatic void generate_blk(
    input logic [N_BYTES_PER_BLK-1:0] i_ctrl,
    input logic [W_BLK-1:0] i_data,
    output logic [W_SYNC-1:0] o_sync_data,
    output logic [W_PLD_BLK-1:0] o_pld_blk
);
    o_sync_data = SYNC_CTRL;
    // Default is error block in case nothing matches
    o_pld_blk = {{8{CODE_ERR}}, C_TYPE};
    case (1'b1)
        // DDDDDDDD
        is_data_block(i_ctrl): begin
            o_sync_data = SYNC_DATA;
            o_pld_blk = i_data;
        end
        // CCCCCCCC
        is_c_block(i_ctrl, i_data): begin
            o_pld_blk[7:0] = C_TYPE;
            o_pld_blk[63:8] = {8{CODE_IDLE}};
        end
        // SDDDDDDD
        is_s0_block(i_ctrl, i_data): begin
            o_pld_blk[7:0] = S0_TYPE;
            o_pld_blk[63:8] = i_data[63:8];
        end
        // CCCCSDDD
        is_s4_block(i_ctrl, i_data): begin
            o_pld_blk[7:0] = S4_TYPE;
            o_pld_blk[39:8] = '0;
            o_pld_blk[63:40] = i_data[63:40];
        end
        // TCCCCCCC
        is_t0_block(i_ctrl, i_data): begin
            o_pld_blk[7:0] = T0_TYPE;
            o_pld_blk[63:8] = '0;
        end
        // DTCCCCCC
        is_t1_block(i_ctrl, i_data): begin
            o_pld_blk[7:0] = T1_TYPE;
            o_pld_blk[15:8] = i_data[7:0];
            o_pld_blk[63:16] = '0;
        end
        // DDTCCCCC
        is_t2_block(i_ctrl, i_data): begin
            o_pld_blk[7:0] = T2_TYPE;
            o_pld_blk[23:8] = i_data[15:0];
            o_pld_blk[63:24] = '0;
        end
        // DDDTCCCC
        is_t3_block(i_ctrl, i_data): begin
            o_pld_blk[7:0] = T3_TYPE;
            o_pld_blk[31:8] = i_data[23:0];
            o_pld_blk[63:32] = '0;
        end
        // DDDDTCCC
        is_t4_block(i_ctrl, i_data): begin
            o_pld_blk[7:0] = T4_TYPE;
            o_pld_blk[39:8] = i_data[31:0];
            o_pld_blk[63:40] = '0;
        end
        // DDDDDTCC
        is_t5_block(i_ctrl, i_data): begin
            o_pld_blk[7:0] = T5_TYPE;
            o_pld_blk[47:8] = i_data[39:0];
            o_pld_blk[63:48] = '0;
        end
        // DDDDDDTC
        is_t6_block(i_ctrl, i_data): begin
            o_pld_blk[7:0] = T6_TYPE;
            o_pld_blk[55:8] = i_data[47:0];
            o_pld_blk[63:56] = '0;
        end
        // DDDDDDDT
        is_t7_block(i_ctrl, i_data): begin
            o_pld_blk[7:0] = T7_TYPE;
            o_pld_blk[63:8] = i_data[55:0];
        end
    endcase
endfunction

logic [N_TRANS_PER_BLK-1:0][N_CHANNELS-1:0] d_ctrl, q_ctrl = '0;
logic [N_TRANS_PER_BLK-1:0][W_DATA-1:0] d_data, q_data = '0;
logic [W_SYNC-1:0] d_sync_data, q_sync_data = '0;
logic [N_TRANS_PER_BLK-1:0][W_DATA-1:0] d_pld_blk, q_pld_blk = '0;
logic err;

always_comb begin : main_logic 
    // error coming from MAC layer will always have
    // all channel data as error, so it's enough to check 1
    err = i_xgmii_ctrl[0] & i_xgmii_data[0] == SYM_ERR;

    d_ctrl = q_ctrl;
    d_data = q_data;

    d_ctrl[i_trans_cnt] = i_xgmii_ctrl;
    d_data[i_trans_cnt] = i_xgmii_data;
    d_sync_data = q_sync_data;
    d_pld_blk   = q_pld_blk;
    if (i_trans_cnt == N_TRANS_PER_BLK-1) begin
        if (!err) begin
            generate_blk(.i_ctrl(d_ctrl),
                         .i_data(d_data),
                         .o_sync_data(d_sync_data),
                         .o_pld_blk(d_pld_blk));
        end
        else begin
            d_sync_data = SYNC_CTRL;
            d_pld_blk = {{8{CODE_ERR}}, C_TYPE};
        end
    end
end

always_ff @(posedge i_clk) begin
    if (i_clk_en) begin
        q_ctrl <= d_ctrl;
        q_data <= d_data;
        q_sync_data <= d_sync_data;
        q_pld_blk <= d_pld_blk;
    end
end

assign o_sync_data = q_sync_data;
assign o_pld_data = q_pld_blk[i_trans_cnt];

endmodule : eth_pcs_64_66_enc