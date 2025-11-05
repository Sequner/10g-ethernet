package mac_params;

import cmn_params::*;

// AXI-Stream interface
localparam W_SYMBOL = W_BYTE;
localparam N_SYMBOLS = W_DATA / W_SYMBOL;

// --- Localparams --- //
// CRC
localparam W_CRC = 32;
localparam N_CRC_BYTE = W_CRC / W_BYTE;
localparam CRC_RESET = 32'hFFFFFFFF;
// inserting inverse correct CRC always results in this value
// https://stackoverflow.com/questions/58393307/verification-of-a-crc-checksum-against-zero 
localparam CRC_MAGIC_NUM = 32'h2144DF1C;

// MIN PLD Counter
localparam N_MIN_PLD   = 64;
localparam N_MIN_TRANS = N_MIN_PLD / N_SYMBOLS;
localparam W_MIN_TRANS = $clog2(N_MIN_TRANS);
localparam INIT_MIN_PLD_CNT = W_CRC / W_DATA;

// MAC HDR 
localparam MAC_HDR_SIZE  = 64;
localparam MAC_HDR_CNT   = MAC_HDR_SIZE / W_DATA;
localparam W_MAC_HDR_CNT = $clog2(MAC_HDR_CNT);

localparam MAC_HDR_DATA = {SYM_SFD,   SYM_PREAM,
                           SYM_PREAM, SYM_PREAM,
                           SYM_PREAM, SYM_PREAM, 
                           SYM_PREAM, SYM_START};
localparam MAC_HDR_CTRL = 8'h01;

// MAC TX Buffer 
localparam MAC_TX_BUF_SIZE = 64; // same as header
localparam N_MAC_TX_BUF = MAC_TX_BUF_SIZE / W_DATA;
localparam W_MAC_TX_BUF = W_DATA + N_CHANNELS;
localparam W_MAC_TX_BUF_CNT = $clog2(N_MAC_TX_BUF);

// Inter-frame Gap (IFG)
localparam W_IFG = 96;
localparam N_IFG_TRANS = W_IFG / W_DATA;
// Initialize 64B part being sent at reset.
// Upon reset, mac_tx_framegen will send
// idle control/data signals right away
// on the next cycle, the data from mac_tx_ctrl is sent
// hence, offset is 1
localparam INIT_MAC_TRANS_ID = 1;

// ---- Functions ---- //
function automatic void calc_crc_32bit (
    input [31:0]  i_crc,
    input [31:0]  i_data,
    output [31:0] o_crc
);
    o_crc[0] =  i_crc[0]  ^ i_data[6]  ^ i_data[15] ^ i_crc[9]   ^ i_crc[10] ^ i_data[25] ^ i_crc[30] ^ 
                i_crc[12] ^ i_crc[29]  ^ i_data[1]  ^ i_data[19] ^ i_crc[24] ^ i_data[3]  ^ i_crc[6] ^ 
                i_crc[16] ^ i_data[22] ^ i_data[5]  ^ i_crc[26]  ^ i_data[7] ^ i_crc[28] ^ i_data[0] ^ 
                i_crc[31] ^ i_data[2]  ^ i_data[21] ^ i_data[31] ^ i_crc[25];
    o_crc[1] =  i_crc[0] ^ i_crc[17] ^ i_crc[27] ^ i_data[15] ^ i_crc[9] ^ i_data[25] ^ i_crc[12] ^ 
                i_data[19] ^ i_data[20] ^ i_crc[24] ^ i_data[3] ^ i_crc[6] ^ i_data[30] ^ i_crc[16] ^ 
                i_data[22] ^ i_data[14] ^ i_data[24] ^ i_crc[1] ^ i_data[7] ^ i_crc[28] ^ i_crc[11] ^ 
                i_data[18] ^ i_crc[13] ^ i_data[31] ^ i_data[4] ^ i_crc[7];
    o_crc[2] =  i_crc[0] ^ i_crc[17] ^ i_data[23] ^ i_data[15] ^ i_crc[9] ^ i_data[25] ^ i_crc[2] ^ 
                i_crc[30] ^ i_data[17] ^ i_data[1] ^ i_crc[14] ^ i_crc[24] ^ i_crc[6] ^ i_data[30] ^ 
                i_data[29] ^ i_crc[16] ^ i_data[22] ^ i_data[5] ^ i_crc[26] ^ i_data[14] ^ i_crc[8] ^ 
                i_crc[18] ^ i_data[24] ^ i_crc[1] ^ i_data[7] ^ i_data[0] ^ i_crc[31] ^ i_data[18] ^ 
                i_crc[13] ^ i_data[31] ^ i_data[13] ^ i_crc[7];
    o_crc[3] =  i_crc[17] ^ i_data[23] ^ i_data[6] ^ i_crc[27] ^ i_crc[10] ^ i_crc[9] ^ i_crc[19] ^ 
                i_crc[2] ^ i_data[17] ^ i_crc[14] ^ i_data[30] ^ i_data[12] ^ i_data[29] ^ 
                i_data[22] ^ i_data[14] ^ i_crc[8] ^ i_data[24] ^ i_crc[1] ^ i_crc[18] ^ i_data[16] ^ 
                i_data[0] ^ i_crc[3] ^ i_crc[31] ^ i_data[28] ^ i_data[21] ^ i_crc[15] ^ i_crc[25] ^ 
                i_data[4] ^ i_crc[7] ^ i_data[13];
    o_crc[4] =  i_crc[0] ^ i_data[23] ^ i_data[6] ^ i_data[25] ^ i_crc[19] ^ i_crc[20] ^ i_crc[2] ^ 
                i_crc[30] ^ i_crc[12] ^ i_crc[29] ^ i_data[1] ^ i_data[27] ^ i_crc[4] ^ i_data[19] ^ 
                i_data[20] ^ i_crc[24] ^ i_crc[6] ^ i_data[12] ^ i_data[29] ^ i_crc[8] ^ i_crc[18] ^ 
                i_data[7] ^ i_data[16] ^ i_crc[11] ^ i_data[0] ^ i_crc[3] ^ i_crc[31] ^ i_data[2] ^ 
                i_data[11] ^ i_data[28] ^ i_crc[15] ^ i_data[31] ^ i_data[13] ^ i_crc[25];
    o_crc[5] =  i_crc[0] ^ i_crc[10] ^ i_data[25] ^ i_crc[19] ^ i_crc[20] ^ i_crc[29] ^ i_data[10] ^ 
                i_data[27] ^ i_crc[4] ^ i_crc[24] ^ i_data[3] ^ i_crc[6] ^ i_data[12] ^ i_data[30] ^ 
                i_data[24] ^ i_crc[1] ^ i_data[7] ^ i_crc[28] ^ i_crc[21] ^ i_crc[3] ^ i_data[26] ^ 
                i_data[18] ^ i_crc[13] ^ i_data[2] ^ i_data[11] ^ i_data[28] ^ i_crc[5] ^ 
                i_data[21] ^ i_data[31] ^ i_crc[7];
    o_crc[6] =  i_data[23] ^ i_data[6] ^ i_crc[20] ^ i_crc[2] ^ i_data[25] ^ i_crc[29] ^ i_crc[30] ^ 
                i_data[17] ^ i_crc[22] ^ i_data[1] ^ i_data[10] ^ i_data[27] ^ i_crc[4] ^ i_data[20] ^ 
                i_crc[14] ^ i_data[30] ^ i_data[29] ^ i_crc[6] ^ i_crc[8] ^ i_data[24] ^ i_crc[1] ^ 
                i_crc[11] ^ i_crc[21] ^ i_data[26] ^ i_data[9] ^ i_data[2] ^ i_data[11] ^ i_crc[5] ^ 
                i_crc[25] ^ i_crc[7];
    o_crc[7] =  i_crc[0] ^ i_data[23] ^ i_data[6] ^ i_data[15] ^ i_crc[10] ^ i_crc[2] ^ i_crc[29] ^ 
                i_data[8] ^ i_data[10] ^ i_crc[22] ^ i_crc[24] ^ i_data[3] ^ i_data[29] ^ i_crc[16] ^ 
                i_crc[8] ^ i_data[24] ^ i_data[7] ^ i_crc[28] ^ i_data[16] ^ i_crc[21] ^ i_crc[3] ^ 
                i_data[26] ^ i_data[9] ^ i_data[2] ^ i_crc[23] ^ i_data[28] ^ i_crc[5] ^ i_crc[15] ^ 
                i_data[21] ^ i_data[31] ^ i_crc[25] ^ i_crc[7];
    o_crc[8] =  i_crc[0] ^ i_crc[17] ^ i_data[23] ^ i_crc[10] ^ i_crc[12] ^ i_data[8] ^ i_crc[22] ^ 
                i_data[27] ^ i_crc[4] ^ i_data[19] ^ i_data[20] ^ i_data[3] ^ i_data[30] ^ i_data[14] ^ 
                i_crc[8] ^ i_crc[1] ^ i_crc[28] ^ i_crc[11] ^ i_data[0] ^ i_crc[3] ^ i_crc[31] ^ 
                i_data[9] ^ i_crc[23] ^ i_data[28] ^ i_data[21] ^ i_data[31];
    o_crc[9] =  i_crc[9] ^ i_crc[2] ^ i_crc[29] ^ i_data[8] ^ i_crc[12] ^ i_data[27] ^ i_crc[4] ^ 
                i_data[20] ^ i_data[19] ^ i_data[30] ^ i_data[29] ^ i_crc[24] ^ i_data[22] ^ i_crc[1] ^ 
                i_crc[18] ^ i_crc[11] ^ i_data[7] ^ i_data[26] ^ i_data[18] ^ i_crc[13] ^ i_data[2] ^ 
                i_crc[23] ^ i_crc[5] ^ i_data[13];
    o_crc[10] = i_crc[0] ^ i_data[15] ^ i_crc[9] ^ i_crc[19] ^ i_crc[2] ^ i_crc[29] ^ i_data[17] ^ 
                i_crc[14] ^ i_data[3] ^ i_data[12] ^ i_data[29] ^ i_crc[16] ^ i_data[22] ^ i_data[5] ^ 
                i_crc[26] ^ i_crc[28] ^ i_data[0] ^ i_crc[3] ^ i_data[26] ^ i_crc[31] ^ i_data[18] ^ 
                i_crc[13] ^ i_data[2] ^ i_data[28] ^ i_crc[5] ^ i_data[31];
    o_crc[11] = i_crc[0] ^ i_crc[17] ^ i_crc[27] ^ i_data[6] ^ i_data[15] ^ i_crc[9] ^ i_crc[20] ^ 
                i_crc[12] ^ i_data[17] ^ i_data[27] ^ i_crc[4] ^ i_data[19] ^ i_crc[14] ^ i_crc[24] ^ 
                i_data[3] ^ i_data[30] ^ i_crc[16] ^ i_data[22] ^ i_data[5] ^ i_crc[26] ^ i_data[14] ^ 
                i_crc[1] ^ i_data[7] ^ i_crc[28] ^ i_data[16] ^ i_data[0] ^ i_crc[3] ^ i_crc[31] ^ 
                i_data[11] ^ i_data[28] ^ i_crc[15] ^ i_data[31] ^ i_data[4] ^ i_crc[25];
    o_crc[12] = i_crc[0] ^ i_crc[17] ^ i_crc[27] ^ i_crc[9] ^ i_data[25] ^ i_crc[2] ^ i_crc[30] ^ 
                i_crc[12] ^ i_data[1] ^ i_data[10] ^ i_data[27] ^ i_crc[4] ^ i_data[19] ^ i_crc[24] ^ 
                i_crc[6] ^ i_data[30] ^ i_data[29] ^ i_data[22] ^ i_data[14] ^ i_crc[18] ^ i_crc[1] ^ 
                i_data[7] ^ i_data[16] ^ i_data[0] ^ i_crc[21] ^ i_data[26] ^ i_crc[31] ^ i_data[18] ^ 
                i_crc[13] ^ i_crc[5] ^ i_crc[15] ^ i_data[31] ^ i_data[13] ^ i_data[4];
    o_crc[13] = i_data[6] ^ i_data[15] ^ i_crc[10] ^ i_crc[19] ^ i_crc[2] ^ i_data[25] ^ i_data[17] ^ 
                i_crc[22] ^ i_crc[14] ^ i_data[30] ^ i_data[12] ^ i_data[3] ^ i_data[29] ^ i_crc[6] ^ 
                i_crc[16] ^ i_data[24] ^ i_crc[1] ^ i_crc[18] ^ i_crc[28] ^ i_data[0] ^ i_crc[3] ^ 
                i_data[26] ^ i_data[18] ^ i_crc[31] ^ i_data[9] ^ i_crc[13] ^ i_data[28] ^ i_crc[5] ^ 
                i_data[21] ^ i_crc[25] ^ i_crc[7] ^ i_data[13];
    o_crc[14] = i_data[23] ^ i_crc[17] ^ i_crc[20] ^ i_crc[2] ^ i_crc[19] ^ i_data[25] ^ i_data[17] ^ 
                i_crc[29] ^ i_data[8] ^ i_data[27] ^ i_crc[4] ^ i_crc[14] ^ i_data[20] ^ i_data[29] ^ 
                i_data[12] ^ i_crc[6] ^ i_data[5] ^ i_crc[26] ^ i_data[14] ^ i_crc[8] ^ i_data[24] ^ 
                i_crc[11] ^ i_data[16] ^ i_crc[3] ^ i_data[11] ^ i_data[2] ^ i_crc[23] ^ i_data[28] ^ 
                i_crc[15] ^ i_crc[7];
    o_crc[15] = i_data[23] ^ i_crc[27] ^ i_crc[9] ^ i_data[15] ^ i_crc[20] ^ i_crc[30] ^ i_crc[12] ^ 
                i_data[10] ^ i_data[1] ^ i_data[27] ^ i_crc[4] ^ i_data[19] ^ i_crc[24] ^ i_data[22] ^ 
                i_crc[16] ^ i_crc[8] ^ i_crc[18] ^ i_data[24] ^ i_data[16] ^ i_data[7] ^ i_crc[21] ^ 
                i_crc[3] ^ i_data[26] ^ i_data[28] ^ i_data[11] ^ i_crc[5] ^ i_crc[15] ^ i_data[4] ^ 
                i_data[13] ^ i_crc[7];
    o_crc[16] = i_crc[0] ^ i_crc[17] ^ i_data[23] ^ i_crc[19] ^ i_crc[30] ^ i_crc[12] ^ i_crc[29] ^ 
                i_data[1] ^ i_data[10] ^ i_crc[22] ^ i_data[27] ^ i_crc[4] ^ i_data[19] ^ i_crc[24] ^ 
                i_data[12] ^ i_data[5] ^ i_crc[26] ^ i_data[14] ^ i_crc[8] ^ i_data[7] ^ i_crc[21] ^ 
                i_data[26] ^ i_data[9] ^ i_data[18] ^ i_crc[13] ^ i_data[2] ^ i_crc[5] ^ i_data[31];
    o_crc[17] = i_data[6] ^ i_crc[27] ^ i_crc[9] ^ i_crc[20] ^ i_data[25] ^ i_data[8] ^ i_crc[30] ^ 
                i_data[17] ^ i_crc[22] ^ i_data[1] ^ i_crc[14] ^ i_data[30] ^ i_crc[6] ^ i_data[22] ^ 
                i_crc[1] ^ i_crc[18] ^ i_data[0] ^ i_data[26] ^ i_data[18] ^ i_crc[31] ^ i_data[9] ^ 
                i_crc[13] ^ i_crc[23] ^ i_data[11] ^ i_crc[5] ^ i_crc[25] ^ i_data[4] ^ i_data[13];
    o_crc[18] = i_crc[10] ^ i_crc[2] ^ i_data[25] ^ i_crc[19] ^ i_data[17] ^ i_data[8] ^ i_data[10] ^ 
                i_crc[14] ^ i_data[29] ^ i_crc[24] ^ i_data[3] ^ i_crc[6] ^ i_data[12] ^ i_data[5] ^ 
                i_crc[26] ^ i_data[24] ^ i_data[7] ^ i_crc[28] ^ i_data[16] ^ i_data[0] ^ i_crc[21] ^ 
                i_crc[31] ^ i_crc[23] ^ i_crc[15] ^ i_data[21] ^ i_crc[7];
    o_crc[19] = i_data[23] ^ i_crc[27] ^ i_data[6] ^ i_data[15] ^ i_crc[20] ^ i_crc[29] ^ i_crc[22] ^ 
                i_data[20] ^ i_crc[24] ^ i_crc[16] ^ i_crc[8] ^ i_data[24] ^ i_data[16] ^ i_data[7] ^ 
                i_crc[11] ^ i_crc[3] ^ i_data[9] ^ i_data[28] ^ i_data[2] ^ i_data[11] ^ i_crc[15] ^ 
                i_data[4] ^ i_crc[25] ^ i_crc[7];
    o_crc[20] = i_data[23] ^ i_crc[17] ^ i_data[15] ^ i_data[6] ^ i_crc[9] ^ i_crc[30] ^ i_data[8] ^ 
                i_crc[12] ^ i_data[27] ^ i_data[1] ^ i_crc[4] ^ i_data[10] ^ i_data[19] ^ i_data[3] ^ 
                i_crc[16] ^ i_data[22] ^ i_data[5] ^ i_crc[26] ^ i_data[14] ^ i_crc[8] ^ i_crc[28] ^ 
                i_crc[21] ^ i_crc[23] ^ i_crc[25];
    o_crc[21] = i_crc[17] ^ i_crc[27] ^ i_crc[9] ^ i_crc[10] ^ i_crc[29] ^ i_crc[22] ^ i_crc[24] ^ 
                i_data[22] ^ i_data[14] ^ i_data[5] ^ i_crc[26] ^ i_crc[18] ^ i_data[7] ^ i_data[26] ^ 
                i_data[0] ^ i_crc[31] ^ i_data[9] ^ i_data[18] ^ i_crc[13] ^ i_data[2] ^ i_crc[5] ^ 
                i_data[21] ^ i_data[4] ^ i_data[13];
    o_crc[22] = i_crc[0] ^ i_crc[27] ^ i_data[15] ^ i_crc[9] ^ i_crc[19] ^ i_crc[12] ^ i_crc[29] ^ 
                i_data[8] ^ i_data[17] ^ i_data[19] ^ i_data[20] ^ i_crc[14] ^ i_crc[24] ^ i_data[12] ^ 
                i_crc[16] ^ i_data[22] ^ i_data[5] ^ i_crc[26] ^ i_crc[18] ^ i_data[7] ^ i_crc[11] ^ 
                i_data[0] ^ i_crc[31] ^ i_data[2] ^ i_crc[23] ^ i_data[31] ^ i_data[13] ^ i_data[4];
    o_crc[23] = i_crc[0] ^ i_crc[17] ^ i_crc[27] ^ i_data[15] ^ i_crc[9] ^ i_data[25] ^ i_crc[19] ^ 
                i_crc[20] ^ i_crc[29] ^ i_crc[6] ^ i_data[12] ^ i_data[30] ^ i_crc[16] ^ i_data[22] ^ 
                i_data[5] ^ i_crc[26] ^ i_data[14] ^ i_crc[1] ^ i_data[16] ^ i_data[0] ^ i_crc[31] ^ 
                i_data[18] ^ i_crc[13] ^ i_data[2] ^ i_data[11] ^ i_crc[15] ^ i_data[31] ^ i_data[4];
    o_crc[24] = i_crc[17] ^ i_data[15] ^ i_crc[27] ^ i_crc[10] ^ i_crc[20] ^ i_crc[2] ^ i_crc[30] ^ 
                i_data[17] ^ i_data[1] ^ i_data[10] ^ i_crc[14] ^ i_data[30] ^ i_data[3] ^ i_data[29] ^ 
                i_crc[16] ^ i_data[14] ^ i_data[24] ^ i_crc[1] ^ i_crc[18] ^ i_crc[28] ^ i_crc[21] ^ 
                i_data[11] ^ i_data[21] ^ i_data[4] ^ i_crc[7] ^ i_data[13];
    o_crc[25] = i_data[23] ^ i_crc[17] ^ i_crc[2] ^ i_crc[19] ^ i_crc[29] ^ i_data[10] ^ i_crc[22] ^ 
                i_data[20] ^ i_data[29] ^ i_data[3] ^ i_data[12] ^ i_data[14] ^ i_crc[8] ^ i_crc[18] ^ 
                i_crc[28] ^ i_crc[11] ^ i_data[16] ^ i_data[0] ^ i_crc[21] ^ i_crc[3] ^ i_crc[31] ^ 
                i_data[9] ^ i_data[2] ^ i_data[28] ^ i_crc[15] ^ i_data[13];
    o_crc[26] = i_crc[0] ^ i_data[6] ^ i_crc[10] ^ i_data[25] ^ i_crc[19] ^ i_crc[20] ^ i_data[8] ^ 
                i_crc[22] ^ i_data[27] ^ i_crc[4] ^ i_crc[24] ^ i_data[3] ^ i_crc[6] ^ i_data[12] ^ 
                i_data[5] ^ i_crc[26] ^ i_crc[18] ^ i_data[7] ^ i_crc[28] ^ i_data[0] ^ i_crc[3] ^ 
                i_crc[31] ^ i_data[9] ^ i_data[11] ^ i_data[28] ^ i_crc[23] ^ i_data[21] ^ i_data[31] ^ 
                i_data[13] ^ i_crc[25];
    o_crc[27] = i_data[6] ^ i_crc[27] ^ i_crc[19] ^ i_crc[20] ^ i_crc[29] ^ i_data[8] ^ i_data[10] ^ 
                i_data[27] ^ i_crc[4] ^ i_data[20] ^ i_data[30] ^ i_data[12] ^ i_crc[24] ^ i_data[5] ^ 
                i_crc[26] ^ i_data[24] ^ i_crc[1] ^ i_crc[11] ^ i_data[7] ^ i_crc[21] ^ i_data[26] ^ 
                i_data[2] ^ i_crc[23] ^ i_data[11] ^ i_crc[5] ^ i_crc[25] ^ i_data[4] ^ i_crc[7];
    o_crc[28] = i_data[23] ^ i_crc[27] ^ i_data[6] ^ i_crc[20] ^ i_crc[2] ^ i_data[25] ^ i_crc[30] ^ 
                i_crc[12] ^ i_data[1] ^ i_data[10] ^ i_crc[22] ^ i_data[19] ^ i_data[29] ^ i_crc[24] ^ 
                i_data[3] ^ i_crc[6] ^ i_data[5] ^ i_crc[26] ^ i_crc[8] ^ i_data[7] ^ i_crc[28] ^ 
                i_crc[21] ^ i_data[26] ^ i_data[9] ^ i_data[11] ^ i_crc[5] ^ i_data[4] ^ i_crc[25];
    o_crc[29] = i_crc[27] ^ i_data[6] ^ i_crc[9] ^ i_data[25] ^ i_crc[29] ^ i_data[8] ^ i_data[10] ^ 
                i_crc[22] ^ i_data[3] ^ i_crc[6] ^ i_data[22] ^ i_data[5] ^ i_crc[26] ^ i_data[24] ^ 
                i_crc[28] ^ i_data[0] ^ i_crc[21] ^ i_crc[3] ^ i_crc[31] ^ i_data[9] ^ i_data[18] ^ 
                i_crc[13] ^ i_data[28] ^ i_data[2] ^ i_crc[23] ^ i_data[4] ^ i_crc[25] ^ i_crc[7];
    o_crc[30] = i_data[23] ^ i_crc[10] ^ i_crc[27] ^ i_crc[29] ^ i_crc[30] ^ i_data[8] ^ i_data[17] ^ 
                i_data[27] ^ i_crc[22] ^ i_data[1] ^ i_crc[4] ^ i_crc[14] ^ i_data[3] ^ i_crc[24] ^ 
                i_data[5] ^ i_crc[26] ^ i_crc[8] ^ i_data[24] ^ i_crc[28] ^ i_data[7] ^ i_data[9] ^ 
                i_data[2] ^ i_crc[23] ^ i_data[21] ^ i_data[4] ^ i_crc[7];
    o_crc[31] = i_data[23] ^ i_crc[27] ^ i_data[6] ^ i_crc[9] ^ i_data[8] ^ i_crc[29] ^ i_crc[30] ^ 
                i_data[1] ^ i_data[20] ^ i_crc[24] ^ i_data[3] ^ i_data[22] ^ i_crc[8] ^ i_crc[11] ^ 
                i_data[7] ^ i_data[16] ^ i_crc[28] ^ i_data[26] ^ i_data[0] ^ i_crc[31] ^ i_data[2] ^ 
                i_crc[23] ^ i_crc[5] ^ i_crc[15] ^ i_data[4] ^ i_crc[25];
endfunction

function automatic void calc_crc_24bit (
    input  [31:0] i_crc,
    input  [23:0] i_data,
    output [31:0] o_crc
);
    o_crc[0] =  i_data[23] ^ i_crc[17] ^ i_crc[20] ^ i_data[17] ^ i_crc[14] ^ i_crc[24] ^ i_crc[8] ^ 
                i_data[14] ^ i_crc[18] ^ i_data[7] ^ i_data[11] ^ i_data[13];
    o_crc[1] =  i_data[23] ^ i_crc[17] ^ i_data[6] ^ i_crc[9] ^ i_crc[20] ^ i_crc[19] ^ i_data[17] ^ 
                i_data[10] ^ i_crc[14] ^ i_crc[24] ^ i_data[12] ^ i_data[22] ^ i_data[14] ^ i_crc[8] ^ 
                i_data[7] ^ i_data[16] ^ i_crc[21] ^ i_data[11] ^ i_crc[15] ^ i_crc[25];
    o_crc[2] =  i_data[23] ^ i_crc[17] ^ i_data[6] ^ i_crc[9] ^ i_data[15] ^ i_crc[10] ^ i_data[17] ^ 
                i_data[10] ^ i_crc[22] ^ i_crc[14] ^ i_crc[24] ^ i_data[22] ^ i_crc[16] ^ i_data[5] ^ 
                i_crc[26] ^ i_data[14] ^ i_crc[8] ^ i_data[7] ^ i_data[16] ^ i_crc[21] ^ i_data[9] ^ 
                i_crc[15] ^ i_data[21] ^ i_crc[25];
    o_crc[3] =  i_crc[17] ^ i_crc[27] ^ i_data[6] ^ i_crc[9] ^ i_data[15] ^ i_crc[10] ^ i_data[8] ^ 
                i_crc[22] ^ i_data[20] ^ i_data[22] ^ i_crc[16] ^ i_data[5] ^ i_crc[26] ^ i_data[14] ^ 
                i_crc[18] ^ i_data[16] ^ i_crc[11] ^ i_data[9] ^ i_crc[23] ^ i_crc[15] ^ i_data[21] ^ 
                i_data[4] ^ i_crc[25] ^ i_data[13];
    o_crc[4] =  i_data[23] ^ i_crc[27] ^ i_data[15] ^ i_crc[10] ^ i_crc[20] ^ i_crc[19] ^ i_data[17] ^ 
                i_data[8] ^ i_crc[12] ^ i_crc[14] ^ i_data[20] ^ i_data[19] ^ i_data[3] ^ i_data[12] ^ 
                i_crc[16] ^ i_data[5] ^ i_crc[26] ^ i_crc[8] ^ i_crc[28] ^ i_crc[11] ^ i_data[11] ^ 
                i_crc[23] ^ i_data[21] ^ i_data[4];
    o_crc[5] =  i_data[23] ^ i_crc[27] ^ i_crc[9] ^ i_data[17] ^ i_crc[29] ^ i_crc[12] ^ i_data[10] ^ 
                i_crc[14] ^ i_data[20] ^ i_data[19] ^ i_data[3] ^ i_data[22] ^ i_crc[8] ^ i_crc[18] ^ 
                i_crc[28] ^ i_data[16] ^ i_crc[11] ^ i_crc[21] ^ i_data[18] ^ i_crc[13] ^ i_data[2] ^ 
                i_crc[15] ^ i_data[4] ^ i_data[13];
    o_crc[6] =  i_crc[9] ^ i_data[15] ^ i_crc[10] ^ i_crc[19] ^ i_crc[30] ^ i_crc[29] ^ i_crc[12] ^ 
                i_data[17] ^ i_data[1] ^ i_crc[22] ^ i_data[19] ^ i_crc[14] ^ i_data[3] ^ i_data[12] ^ 
                i_data[22] ^ i_crc[16] ^ i_data[16] ^ i_crc[28] ^ i_data[9] ^ i_data[18] ^ i_crc[13] ^ 
                i_data[2] ^ i_crc[15] ^ i_data[21];
    o_crc[7] =  i_data[23] ^ i_data[15] ^ i_crc[10] ^ i_crc[29] ^ i_crc[30] ^ i_data[8] ^ i_data[1] ^ 
                i_data[20] ^ i_crc[24] ^ i_crc[16] ^ i_crc[8] ^ i_crc[18] ^ i_data[7] ^ i_crc[11] ^ 
                i_data[16] ^ i_data[0] ^ i_crc[31] ^ i_data[18] ^ i_crc[13] ^ i_data[2] ^ i_crc[23] ^ 
                i_data[21] ^ i_crc[15] ^ i_data[13];
    o_crc[8] =  i_data[23] ^ i_data[6] ^ i_crc[9] ^ i_data[15] ^ i_crc[20] ^ i_crc[19] ^ i_crc[30] ^ 
                i_crc[12] ^ i_data[1] ^ i_data[20] ^ i_data[19] ^ i_data[12] ^ i_data[22] ^ i_crc[16] ^ 
                i_crc[8] ^ i_crc[18] ^ i_crc[11] ^ i_data[0] ^ i_crc[31] ^ i_data[11] ^ i_data[13] ^ 
                i_crc[25];
    o_crc[9] =  i_crc[17] ^ i_crc[9] ^ i_crc[10] ^ i_crc[19] ^ i_crc[20] ^ i_crc[12] ^ i_data[10] ^ 
                i_data[19] ^ i_data[12] ^ i_data[22] ^ i_data[5] ^ i_crc[26] ^ i_data[14] ^ i_data[0] ^ 
                i_crc[21] ^ i_crc[31] ^ i_data[18] ^ i_crc[13] ^ i_data[11] ^ i_data[21];
    o_crc[10] = i_data[23] ^ i_crc[17] ^ i_crc[27] ^ i_crc[10] ^ i_crc[22] ^ i_data[10] ^ i_data[20] ^ 
                i_crc[24] ^ i_data[14] ^ i_crc[8] ^ i_data[7] ^ i_crc[11] ^ i_crc[21] ^ i_data[9] ^ 
                i_data[18] ^ i_crc[13] ^ i_data[21] ^ i_data[4];
    o_crc[11] = i_data[23] ^ i_crc[17] ^ i_data[6] ^ i_crc[9] ^ i_crc[20] ^ i_data[8] ^ i_crc[12] ^ 
                i_crc[22] ^ i_data[20] ^ i_data[19] ^ i_crc[24] ^ i_data[3] ^ i_data[22] ^ i_data[14] ^
                i_crc[8] ^ i_data[7] ^ i_crc[28] ^ i_crc[11] ^ i_data[9] ^ i_data[11] ^ i_crc[23] ^ 
                i_crc[25];
    o_crc[12] = i_data[23] ^ i_crc[17] ^ i_data[6] ^ i_crc[9] ^ i_crc[10] ^ i_crc[20] ^ i_data[17] ^ 
                i_crc[29] ^ i_data[8] ^ i_crc[12] ^ i_data[10] ^ i_crc[14] ^ i_data[19] ^ i_data[22] ^ 
                i_data[5] ^ i_crc[26] ^ i_data[14] ^ i_crc[8] ^ i_crc[21] ^ i_data[18] ^ i_crc[13] ^ 
                i_data[11] ^ i_data[2] ^ i_crc[23] ^ i_data[21] ^ i_crc[25];
    o_crc[13] = i_crc[27] ^ i_crc[9] ^ i_crc[10] ^ i_crc[30] ^ i_data[17] ^ i_data[10] ^ i_data[1] ^ 
                i_crc[22] ^ i_data[20] ^ i_crc[14] ^ i_crc[24] ^ i_data[22] ^ i_data[5] ^ i_crc[26] ^ 
                i_crc[18] ^ i_data[16] ^ i_data[7] ^ i_crc[11] ^ i_crc[21] ^ i_data[9] ^ i_data[18] ^ 
                i_crc[13] ^ i_crc[15] ^ i_data[21] ^ i_data[4] ^ i_data[13];
    o_crc[14] = i_data[15] ^ i_data[6] ^ i_crc[10] ^ i_crc[27] ^ i_crc[19] ^ i_data[8] ^ i_crc[12] ^ 
                i_data[17] ^ i_crc[22] ^ i_data[20] ^ i_data[19] ^ i_crc[14] ^ i_data[3] ^ i_data[12] ^ 
                i_crc[16] ^ i_crc[28] ^ i_crc[11] ^ i_data[16] ^ i_data[0] ^ i_data[9] ^ i_crc[31] ^ 
                i_crc[23] ^ i_data[21] ^ i_crc[15] ^ i_crc[25] ^ i_data[4];
    o_crc[15] = i_crc[17] ^ i_data[15] ^ i_crc[20] ^ i_data[8] ^ i_crc[29] ^ i_crc[12] ^ i_data[20] ^ 
                i_data[19] ^ i_crc[24] ^ i_data[3] ^ i_crc[16] ^ i_data[14] ^ i_data[5] ^ i_crc[26] ^ 
                i_crc[11] ^ i_data[7] ^ i_crc[28] ^ i_data[16] ^ i_data[18] ^ i_crc[13] ^ i_data[2] ^ 
                i_crc[23] ^ i_data[11] ^ i_crc[15];
    o_crc[16] = i_data[23] ^ i_crc[27] ^ i_data[6] ^ i_data[15] ^ i_crc[20] ^ i_crc[29] ^ i_crc[30] ^ 
                i_crc[12] ^ i_data[1] ^ i_data[10] ^ i_data[19] ^ i_crc[16] ^ i_crc[8] ^ i_crc[21] ^ 
                i_data[18] ^ i_crc[13] ^ i_data[11] ^ i_data[2] ^ i_data[4] ^ i_crc[25];
    o_crc[17] = i_crc[17] ^ i_crc[9] ^ i_crc[30] ^ i_data[17] ^ i_data[10] ^ i_data[1] ^ i_crc[22] ^ 
                i_crc[14] ^ i_data[3] ^ i_data[22] ^ i_data[5] ^ i_crc[26] ^ i_data[14] ^ i_crc[28] ^ 
                i_data[0] ^ i_crc[21] ^ i_crc[31] ^ i_data[18] ^ i_data[9] ^ i_crc[13];
    o_crc[18] = i_crc[10] ^ i_crc[27] ^ i_crc[29] ^ i_data[17] ^ i_data[8] ^ i_crc[22] ^ i_crc[14] ^ 
                i_crc[18] ^ i_data[16] ^ i_data[0] ^ i_data[9] ^ i_crc[31] ^ i_data[2] ^ i_crc[23] ^ 
                i_data[21] ^ i_crc[15] ^ i_data[4] ^ i_data[13];
    o_crc[19] = i_data[15] ^ i_crc[19] ^ i_data[8] ^ i_crc[30] ^ i_data[1] ^ i_data[20] ^ i_crc[24] ^ 
                i_data[3] ^ i_data[12] ^ i_crc[16] ^ i_crc[11] ^ i_data[16] ^ i_data[7] ^ i_crc[28] ^ 
                i_crc[23] ^ i_crc[15];
    o_crc[20] = i_crc[17] ^ i_data[15] ^ i_data[6] ^ i_crc[20] ^ i_crc[12] ^ i_crc[29] ^ i_data[19] ^ 
                i_crc[24] ^ i_crc[16] ^ i_data[14] ^ i_data[7] ^ i_data[0] ^ i_crc[31] ^ i_data[2] ^ 
                i_data[11] ^ i_crc[25];
    o_crc[21] = i_crc[17] ^ i_data[6] ^ i_crc[30] ^ i_data[1] ^ i_data[10] ^ i_data[14] ^ i_data[5] ^ 
                i_crc[26] ^ i_crc[18] ^ i_crc[21] ^ i_data[18] ^ i_crc[13] ^ i_crc[25] ^ i_data[13];
    o_crc[22] = i_data[23] ^ i_crc[17] ^ i_crc[27] ^ i_crc[20] ^ i_crc[19] ^ i_crc[22] ^ i_crc[24] ^ 
                i_data[12] ^ i_data[5] ^ i_crc[26] ^ i_data[14] ^ i_crc[8] ^ i_data[7] ^ i_data[0] ^ 
                i_crc[31] ^ i_data[9] ^ i_data[11] ^ i_data[4];
    o_crc[23] = i_data[23] ^ i_crc[17] ^ i_crc[27] ^ i_data[6] ^ i_crc[9] ^ i_data[17] ^ i_data[8] ^ 
                i_data[10] ^ i_crc[14] ^ i_crc[24] ^ i_data[3] ^ i_data[22] ^ i_data[14] ^ i_crc[8] ^ 
                i_data[7] ^ i_crc[28] ^ i_crc[21] ^ i_crc[23] ^ i_data[4] ^ i_crc[25];
    o_crc[24] = i_crc[0] ^ i_data[6] ^ i_crc[9] ^ i_crc[10] ^ i_crc[29] ^ i_crc[22] ^ i_crc[24] ^ 
                i_data[3] ^ i_data[22] ^ i_data[5] ^ i_crc[26] ^ i_crc[18] ^ i_data[16] ^ i_data[7] ^ 
                i_crc[28] ^ i_data[9] ^ i_data[2] ^ i_crc[15] ^ i_data[21] ^ i_crc[25] ^ i_data[13];
    o_crc[25] = i_data[15] ^ i_data[6] ^ i_crc[10] ^ i_crc[27] ^ i_crc[19] ^ i_crc[29] ^ i_crc[30] ^ 
                i_data[8] ^ i_data[1] ^ i_data[20] ^ i_data[12] ^ i_crc[16] ^ i_data[5] ^ i_crc[26] ^ 
                i_crc[1] ^ i_crc[11] ^ i_data[2] ^ i_crc[23] ^ i_data[21] ^ i_crc[25] ^ i_data[4];
    o_crc[26] = i_data[23] ^ i_crc[27] ^ i_crc[2] ^ i_data[17] ^ i_crc[30] ^ i_crc[12] ^ i_data[1] ^ 
                i_crc[14] ^ i_data[20] ^ i_data[19] ^ i_data[3] ^ i_data[5] ^ i_crc[26] ^ i_crc[8] ^ 
                i_crc[18] ^ i_crc[28] ^ i_crc[11] ^ i_data[0] ^ i_crc[31] ^ i_data[4] ^ i_data[13];
    o_crc[27] = i_crc[27] ^ i_crc[9] ^ i_crc[19] ^ i_crc[29] ^ i_crc[12] ^ i_data[19] ^ i_data[3] ^ 
                i_data[12] ^ i_data[22] ^ i_data[16] ^ i_crc[28] ^ i_data[0] ^ i_crc[3] ^ i_crc[31] ^ 
                i_data[18] ^ i_crc[13] ^ i_data[2] ^ i_crc[15] ^ i_data[4];
    o_crc[28] = i_data[15] ^ i_crc[10] ^ i_crc[20] ^ i_crc[29] ^ i_crc[30] ^ i_data[17] ^ i_data[1] ^ 
                i_crc[4] ^ i_crc[14] ^ i_data[3] ^ i_crc[16] ^ i_crc[28] ^ i_data[18] ^ i_crc[13] ^ 
                i_data[2] ^ i_data[11] ^ i_data[21];
    o_crc[29] = i_crc[17] ^ i_crc[29] ^ i_crc[30] ^ i_data[17] ^ i_data[1] ^ i_data[10] ^ i_data[20] ^ 
                i_crc[14] ^ i_data[14] ^ i_crc[11] ^ i_data[16] ^ i_data[0] ^ i_crc[21] ^ i_crc[31] ^ 
                i_data[2] ^ i_crc[5] ^ i_crc[15];
    o_crc[30] = i_data[15] ^ i_crc[30] ^ i_crc[12] ^ i_data[1] ^ i_crc[22] ^ i_data[19] ^ i_crc[6] ^ 
                i_crc[16] ^ i_crc[18] ^ i_data[16] ^ i_data[0] ^ i_crc[31] ^ i_data[9] ^ i_crc[15] ^ 
                i_data[13];
    o_crc[31] = i_crc[17] ^ i_data[15] ^ i_crc[19] ^ i_data[8] ^ i_data[12] ^ i_crc[16] ^ i_data[14] ^ 
                i_data[0] ^ i_data[18] ^ i_crc[31] ^ i_crc[13] ^ i_crc[23] ^ i_crc[7];
endfunction

function automatic void calc_crc_16bit (
    input  [31:0] i_crc,
    input  [23:0] i_data,
    output [31:0] o_crc
);
    o_crc[0]  = i_data[9] ^ i_crc[22] ^ i_data[5] ^ i_crc[26] ^ i_data[15] ^ i_data[6] ^ i_data[3] ^ i_crc[28] ^ i_crc[25] ^ i_crc[16];
    o_crc[1]  = i_crc[17] ^ i_data[15] ^ i_data[6] ^ i_crc[27] ^ i_crc[29] ^ i_data[8] ^ i_crc[22] ^ i_data[3] ^ i_crc[16] ^ i_data[14] ^ i_crc[28] ^ i_data[9] ^ i_crc[23] ^ i_data[2] ^ i_data[4] ^ i_crc[25];
    o_crc[2]  = i_crc[17] ^ i_data[15] ^ i_data[6] ^ i_data[8] ^ i_crc[29] ^ i_crc[30] ^ i_crc[22] ^ i_data[1] ^ i_crc[24] ^ i_crc[16] ^ i_data[14] ^ i_crc[18] ^ i_data[7] ^ i_data[9] ^ i_data[2] ^ i_crc[23] ^ i_crc[25] ^ i_data[13];
    o_crc[3]  = i_crc[17] ^ i_data[6] ^ i_crc[19] ^ i_data[8] ^ i_crc[30] ^ i_data[1] ^ i_crc[24] ^ i_data[12] ^ i_data[14] ^ i_data[5] ^ i_crc[26] ^ i_crc[18] ^ i_data[7] ^ i_data[0] ^ i_crc[31] ^ i_crc[23] ^ i_data[13] ^ i_crc[25];
    o_crc[4]  = i_data[15] ^ i_crc[27] ^ i_crc[20] ^ i_crc[19] ^ i_crc[22] ^ i_data[3] ^ i_crc[24] ^ i_data[12] ^ i_crc[16] ^ i_crc[18] ^ i_crc[28] ^ i_data[7] ^ i_data[0] ^ i_data[9] ^ i_crc[31] ^ i_data[11] ^ i_data[13] ^ i_data[4];
    o_crc[5]  = i_crc[17] ^ i_data[15] ^ i_crc[19] ^ i_crc[20] ^ i_data[8] ^ i_crc[29] ^ i_crc[22] ^ i_data[10] ^ i_data[12] ^ i_crc[16] ^ i_data[5] ^ i_crc[26] ^ i_data[14] ^ i_crc[21] ^ i_data[9] ^ i_data[2] ^ i_crc[23] ^ i_data[11];
    o_crc[6]  = i_crc[17] ^ i_crc[27] ^ i_crc[20] ^ i_data[8] ^ i_crc[30] ^ i_data[1] ^ i_crc[22] ^ i_data[10] ^ i_crc[24] ^ i_data[14] ^ i_crc[18] ^ i_data[7] ^ i_crc[21] ^ i_data[9] ^ i_crc[23] ^ i_data[11] ^ i_data[4] ^ i_data[13];
    o_crc[7]  = i_data[15] ^ i_crc[19] ^ i_data[8] ^ i_data[10] ^ i_crc[24] ^ i_data[12] ^ i_crc[16] ^ i_data[5] ^ i_crc[26] ^ i_crc[18] ^ i_data[7] ^ i_data[0] ^ i_crc[21] ^ i_crc[31] ^ i_crc[23] ^ i_data[13];
    o_crc[8]  = i_crc[17] ^ i_data[15] ^ i_crc[27] ^ i_crc[19] ^ i_crc[20] ^ i_data[3] ^ i_data[12] ^ i_crc[24] ^ i_crc[16] ^ i_data[5] ^ i_crc[26] ^ i_data[14] ^ i_crc[28] ^ i_data[7] ^ i_data[11] ^ i_data[4];
    o_crc[9]  = i_crc[17] ^ i_crc[27] ^ i_data[6] ^ i_crc[20] ^ i_crc[29] ^ i_data[10] ^ i_data[3] ^ i_data[14] ^ i_crc[18] ^ i_crc[28] ^ i_crc[21] ^ i_data[2] ^ i_data[11] ^ i_data[4] ^ i_data[13] ^ i_crc[25];
    o_crc[10] = i_data[15] ^ i_data[6] ^ i_crc[19] ^ i_crc[30] ^ i_crc[29] ^ i_data[1] ^ i_data[10] ^ i_data[12] ^ i_crc[16] ^ i_crc[18] ^ i_crc[21] ^ i_data[2] ^ i_crc[25] ^ i_data[13];
    o_crc[11] = i_crc[17] ^ i_data[15] ^ i_data[6] ^ i_crc[19] ^ i_crc[20] ^ i_crc[30] ^ i_data[1] ^ i_data[3] ^ i_data[12] ^ i_crc[16] ^ i_data[14] ^ i_crc[28] ^ i_data[0] ^ i_crc[31] ^ i_data[11] ^ i_crc[25];
    o_crc[12] = i_crc[17] ^ i_data[15] ^ i_data[6] ^ i_crc[20] ^ i_crc[29] ^ i_crc[22] ^ i_data[10] ^ i_data[3] ^ i_crc[16] ^ i_data[14] ^ i_crc[18] ^ i_crc[28] ^ i_data[0] ^ i_crc[21] ^ i_data[9] ^ i_crc[31] ^ i_data[2] ^ i_data[11] ^ i_crc[25] ^ i_data[13];
    o_crc[13] = i_crc[17] ^ i_crc[19] ^ i_data[8] ^ i_crc[29] ^ i_crc[30] ^ i_data[1] ^ i_data[10] ^ i_crc[22] ^ i_data[12] ^ i_data[14] ^ i_data[5] ^ i_crc[26] ^ i_crc[18] ^ i_crc[21] ^ i_data[9] ^ i_data[2] ^ i_crc[23] ^ i_data[13];
    o_crc[14] = i_crc[27] ^ i_crc[19] ^ i_crc[20] ^ i_crc[30] ^ i_data[8] ^ i_data[1] ^ i_crc[22] ^ i_crc[24] ^ i_data[12] ^ i_crc[18] ^ i_data[7] ^ i_data[0] ^ i_crc[31] ^ i_data[9] ^ i_data[11] ^ i_crc[23] ^ i_data[13] ^ i_data[4];
    o_crc[15] = i_data[6] ^ i_crc[20] ^ i_crc[19] ^ i_data[8] ^ i_data[10] ^ i_data[12] ^ i_crc[24] ^ i_data[3] ^ i_data[7] ^ i_crc[28] ^ i_data[0] ^ i_crc[21] ^ i_crc[31] ^ i_crc[23] ^ i_data[11] ^ i_crc[25];
    o_crc[16] = i_crc[0] ^ i_data[15] ^ i_crc[20] ^ i_crc[29] ^ i_data[10] ^ i_data[3] ^ i_crc[24] ^ i_crc[16] ^ i_crc[28] ^ i_data[7] ^ i_crc[21] ^ i_data[11] ^ i_data[2];
    o_crc[17] = i_crc[17] ^ i_data[6] ^ i_crc[29] ^ i_crc[30] ^ i_data[10] ^ i_data[1] ^ i_crc[22] ^ i_data[14] ^ i_crc[1] ^ i_crc[21] ^ i_data[9] ^ i_data[2] ^ i_crc[25];
    o_crc[18] = i_crc[2] ^ i_crc[30] ^ i_data[8] ^ i_data[1] ^ i_crc[22] ^ i_crc[26] ^ i_data[5] ^ i_crc[18] ^ i_data[0] ^ i_data[9] ^ i_crc[31] ^ i_crc[23] ^ i_data[13];
    o_crc[19] = i_crc[27] ^ i_crc[19] ^ i_data[8] ^ i_data[12] ^ i_crc[24] ^ i_data[7] ^ i_data[0] ^ i_crc[3] ^ i_crc[31] ^ i_crc[23] ^ i_data[4];
    o_crc[20] = i_data[6] ^ i_crc[20] ^ i_crc[4] ^ i_data[3] ^ i_crc[24] ^ i_data[7] ^ i_crc[28] ^ i_data[11] ^ i_crc[25];
    o_crc[21] = i_data[6] ^ i_crc[29] ^ i_data[10] ^ i_crc[26] ^ i_data[5] ^ i_crc[21] ^ i_crc[5] ^ i_data[2] ^ i_crc[25];
    o_crc[22] = i_data[15] ^ i_data[6] ^ i_crc[27] ^ i_crc[30] ^ i_data[1] ^ i_data[3] ^ i_crc[6] ^ i_crc[16] ^ i_crc[28] ^ i_crc[25] ^ i_data[4];
    o_crc[23] = i_crc[17] ^ i_data[15] ^ i_data[6] ^ i_crc[29] ^ i_crc[22] ^ i_crc[16] ^ i_data[14] ^ i_data[0] ^ i_data[9] ^ i_crc[31] ^ i_data[2] ^ i_crc[25] ^ i_crc[7];
    o_crc[24] = i_data[14] ^ i_data[5] ^ i_crc[26] ^ i_crc[17] ^ i_data[1] ^ i_crc[8] ^ i_crc[23] ^ i_crc[18] ^ i_data[8] ^ i_data[13] ^ i_crc[30];
    o_crc[25] = i_crc[31] ^ i_crc[27] ^ i_crc[18] ^ i_crc[9] ^ i_data[7] ^ i_crc[24] ^ i_data[12] ^ i_crc[19] ^ i_data[13] ^ i_data[4] ^ i_data[0];
    o_crc[26] = i_data[15] ^ i_crc[10] ^ i_crc[20] ^ i_crc[19] ^ i_crc[22] ^ i_data[12] ^ i_crc[16] ^ i_data[5] ^ i_crc[26] ^ i_data[9] ^ i_data[11];
    o_crc[27] = i_crc[17] ^ i_crc[27] ^ i_crc[20] ^ i_data[8] ^ i_data[10] ^ i_data[14] ^ i_crc[11] ^ i_crc[21] ^ i_crc[23] ^ i_data[11] ^ i_data[4];
    o_crc[28] = i_crc[12] ^ i_crc[22] ^ i_data[10] ^ i_crc[24] ^ i_data[3] ^ i_crc[18] ^ i_data[7] ^ i_crc[28] ^ i_crc[21] ^ i_data[9] ^ i_data[13];
    o_crc[29] = i_data[6] ^ i_crc[19] ^ i_data[8] ^ i_crc[29] ^ i_crc[22] ^ i_data[12] ^ i_crc[13] ^ i_data[9] ^ i_data[2] ^ i_crc[23] ^ i_crc[25];
    o_crc[30] = i_data[5] ^ i_crc[26] ^ i_data[1] ^ i_data[11] ^ i_crc[23] ^ i_crc[14] ^ i_crc[20] ^ i_data[7] ^ i_crc[24] ^ i_crc[30] ^ i_data[8];
    o_crc[31] = i_data[10] ^ i_crc[31] ^ i_crc[27] ^ i_data[6] ^ i_data[7] ^ i_crc[24] ^ i_crc[15] ^ i_data[4] ^ i_data[0] ^ i_crc[21] ^ i_crc[25];
endfunction

function automatic void calc_crc_8bit (
    input  [31:0] i_crc,
    input  [7:0]  i_data,
    output [31:0] o_crc
);
    o_crc[0] =  i_data[1] ^ i_data[7] ^ i_crc[24] ^ i_crc[30];
    o_crc[1] =  i_data[1] ^ i_crc[31] ^ i_data[6] ^ i_data[7] ^ i_crc[24] ^ i_crc[30] ^ i_data[0] ^ 
                i_crc[25];
    o_crc[2] =  i_data[1] ^ i_crc[31] ^ i_data[5] ^ i_crc[26] ^ i_data[6] ^ i_data[7] ^ i_crc[24] ^ 
                i_crc[30] ^ i_data[0] ^ i_crc[25];
    o_crc[3] =  i_crc[31] ^ i_data[5] ^ i_crc[26] ^ i_data[6] ^ i_crc[27] ^ i_data[0] ^ i_crc[25] ^ 
                i_data[4];
    o_crc[4] =  i_data[1] ^ i_data[5] ^ i_crc[26] ^ i_crc[27] ^ i_data[7] ^ i_crc[24] ^ i_data[3] ^ 
                i_crc[28] ^ i_crc[30] ^ i_data[4];
    o_crc[5] =  i_crc[27] ^ i_data[6] ^ i_crc[30] ^ i_crc[29] ^ i_data[1] ^ i_data[3] ^ i_crc[24] ^ 
                i_data[7] ^ i_crc[28] ^ i_data[0] ^ i_crc[31] ^ i_data[2] ^ i_data[4] ^ i_crc[25];
    o_crc[6] =  i_data[6] ^ i_crc[30] ^ i_crc[29] ^ i_data[1] ^ i_data[3] ^ i_crc[26] ^ i_data[5] ^ 
                i_crc[28] ^ i_data[0] ^ i_crc[31] ^ i_data[2] ^ i_crc[25];
    o_crc[7] =  i_data[5] ^ i_crc[26] ^ i_crc[31] ^ i_crc[27] ^ i_data[2] ^ i_data[7] ^ i_crc[24] ^ 
                i_data[4] ^ i_crc[29] ^ i_data[0];
    o_crc[8] =  i_crc[0] ^ i_data[6] ^ i_crc[27] ^ i_data[7] ^ i_crc[24] ^ i_data[3] ^ i_crc[28] ^ 
                i_crc[25] ^ i_data[4];
    o_crc[9] =  i_data[5] ^ i_crc[26] ^ i_data[6] ^ i_data[2] ^ i_crc[1] ^ i_data[3] ^ i_crc[28] ^ 
                i_crc[25] ^ i_crc[29];
    o_crc[10] = i_data[5] ^ i_crc[26] ^ i_crc[27] ^ i_data[2] ^ i_data[7] ^ i_crc[24] ^ i_crc[2] ^ 
                i_data[4] ^ i_crc[29];
    o_crc[11] = i_data[6] ^ i_crc[27] ^ i_data[7] ^ i_crc[24] ^ i_data[3] ^ i_crc[28] ^ i_crc[25] ^ 
                i_data[4] ^ i_crc[3];
    o_crc[12] = i_data[6] ^ i_crc[29] ^ i_crc[30] ^ i_data[1] ^ i_crc[4] ^ i_data[3] ^ i_crc[24] ^ 
                i_crc[26] ^ i_data[5] ^ i_data[7] ^ i_crc[28] ^ i_data[2] ^ i_crc[25];
    o_crc[13] = i_data[6] ^ i_crc[27] ^ i_crc[30] ^ i_crc[29] ^ i_data[1] ^ i_crc[26] ^ i_data[5] ^ 
                i_data[0] ^ i_crc[31] ^ i_crc[5] ^ i_data[2] ^ i_data[4] ^ i_crc[25];
    o_crc[14] = i_data[5] ^ i_crc[26] ^ i_data[1] ^ i_crc[31] ^ i_crc[27] ^ i_data[3] ^ i_crc[28] ^ 
                i_crc[6] ^ i_data[4] ^ i_crc[30] ^ i_data[0];
    o_crc[15] = i_crc[31] ^ i_crc[27] ^ i_data[2] ^ i_data[3] ^ i_crc[28] ^ i_data[4] ^ i_crc[29] ^ 
                i_data[0] ^ i_crc[7];
    o_crc[16] = i_crc[8] ^ i_data[2] ^ i_data[7] ^ i_crc[24] ^ i_data[3] ^ i_crc[28] ^ i_crc[29];
    o_crc[17] = i_data[1] ^ i_data[6] ^ i_data[2] ^ i_crc[9] ^ i_crc[25] ^ i_crc[29] ^ i_crc[30];
    o_crc[18] = i_data[5] ^ i_crc[26] ^ i_data[1] ^ i_crc[31] ^ i_crc[10] ^ i_crc[30] ^ i_data[0];
    o_crc[19] = i_crc[31] ^ i_crc[27] ^ i_crc[11] ^ i_data[4] ^ i_data[0];
    o_crc[20] = i_data[3] ^ i_crc[28] ^ i_crc[12];
    o_crc[21] = i_crc[13] ^ i_data[2] ^ i_crc[29];
    o_crc[22] = i_crc[14] ^ i_data[7] ^ i_crc[24];
    o_crc[23] = i_data[1] ^ i_data[6] ^ i_data[7] ^ i_crc[24] ^ i_crc[15] ^ i_crc[30] ^ i_crc[25];
    o_crc[24] = i_crc[31] ^ i_data[5] ^ i_crc[26] ^ i_data[6] ^ i_data[0] ^ i_crc[25] ^ i_crc[16];
    o_crc[25] = i_data[5] ^ i_crc[26] ^ i_crc[17] ^ i_crc[27] ^ i_data[4];
    o_crc[26] = i_data[1] ^ i_crc[27] ^ i_crc[18] ^ i_data[7] ^ i_crc[24] ^ i_data[3] ^ i_crc[28] ^ 
                i_crc[30] ^ i_data[4];
    o_crc[27] = i_crc[31] ^ i_data[6] ^ i_data[2] ^ i_data[3] ^ i_crc[28] ^ i_crc[19] ^ i_data[0] ^ 
                i_crc[25] ^ i_crc[29];
    o_crc[28] = i_data[5] ^ i_crc[26] ^ i_data[1] ^ i_data[2] ^ i_crc[20] ^ i_crc[29] ^ i_crc[30];
    o_crc[29] = i_data[1] ^ i_crc[31] ^ i_crc[27] ^ i_data[4] ^ i_crc[30] ^ i_data[0] ^ i_crc[21];
    o_crc[30] = i_crc[31] ^ i_crc[22] ^ i_data[3] ^ i_crc[28] ^ i_data[0];
    o_crc[31] = i_data[2] ^ i_crc[23] ^ i_crc[29];
endfunction

endpackage