package cmn_params;

parameter W_DATA = 32; // only 16 and 32
parameter W_BYTE = 8;

localparam W_BLK = 64;
localparam N_BYTES_PER_BLK = W_BLK / W_BYTE;
localparam W_BYTES_PER_BLK = $clog2(N_BYTES_PER_BLK);
localparam N_TRANS_PER_BLK = W_BLK / W_DATA;
localparam W_TRANS_PER_BLK = $clog2(N_TRANS_PER_BLK);
localparam N_BYTES_PER_TRANS = W_DATA / W_BYTE;

// Symbols
localparam SYM_IDLE  = 8'h07;
localparam SYM_START = 8'hFB;
localparam SYM_TERM  = 8'hFD;
localparam SYM_ERR   = 8'hFE;
localparam SYM_PREAM = 8'h55;
localparam SYM_SFD   = 8'hD5;

endpackage