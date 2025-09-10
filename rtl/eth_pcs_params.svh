package eth_pcs_params;

localparam W_PLD_BLK = W_BLK;

localparam W_SYNC    = 2;
localparam SYNC_DATA = 2'b01;
localparam SYNC_CTRL = 2'b10;

// TX Gearbox
localparam TX_GEARBOX_CNT = 32;
localparam W_TX_GEARBOX_CNT = $clog2(TX_GEARBOX_CNT);
localparam W_TX_GEARBOX_BUF = W_DATA*2;

// RX Block Synch
localparam SH_VAL_TH = 64;
localparam W_SH_VAL_TH = $clog2(SH_VAL_TH);
localparam SH_INVAL_TH = 16;
localparam W_SH_INVAL_TH = $clog2(SH_INVAL_TH);
// RX Gearbox
localparam W_RX_GEARBOX_OFFSET = $clog2(W_DATA);
localparam [W_RX_GEARBOX_OFFSET-1:0] RX_GEARBOX_OFFSET_INIT = W_DATA-2; 

// Encoder/decoder params
localparam C_TYPE = 8'h1E,
           S0_TYPE = 8'h78,
           S4_TYPE = 8'h33,
           T0_TYPE = 8'h87,
           T1_TYPE = 8'h99,
           T2_TYPE = 8'hAA,
           T3_TYPE = 8'hB4,
           T4_TYPE = 8'hCC,
           T5_TYPE = 8'hD2,
           T6_TYPE = 8'hE1,
           T7_TYPE = 8'hFF;

localparam CODE_IDLE = 7'h00,
           CODE_LPI  = 7'h06,
           CODE_ERR  = 7'h1E,
           CODE_RES0 = 7'h2D,
           CODE_RES1 = 7'h33,
           CODE_RES2 = 7'h4B,
           CODE_RES3 = 7'h55,
           CODE_RES4 = 7'h66,
           CODE_RES5 = 7'h78;

// Scrambler params
localparam W_SCR = 58;

endpackage