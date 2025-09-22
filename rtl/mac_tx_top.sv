import cmn_params::*;
import mac_params::*;

module mac_tx_top(
    input i_clk,
    input i_clk_en,
    input i_reset,
    // AXI-Stream Interface
    input  logic s_tvalid,
    input  logic [N_SYMBOLS-1:0] s_tkeep,
    input  logic [N_SYMBOLS-1:0][W_SYMBOL-1:0] s_tdata,
    input  logic s_tlast,
    output logic s_tready,
    // XGMII Interface
    output logic [N_CHANNELS-1:0] o_xgmii_ctrl,
    output logic [N_CHANNELS-1:0][W_BYTE-1:0] o_xgmii_data
);
// TODO: Create 64-bit data analyzer that tells PCS which block type is being sent
// --- Signal Declaration --- //
// Framegen Ctrl
logic [W_MAC_HDR_CNT-1:0] hdr_id;
logic gen_hdr;
logic gen_data;
logic gen_idle;
logic gen_ifg;
logic gen_error;
// Buffer Signals
logic buf_empty;
logic buf_clear;
logic buf_ren; // data is read by framegen
logic buf_wen;
logic [N_CHANNELS-1:0] buf_wctrl;
logic [N_CHANNELS-1:0][W_BYTE-1:0] buf_wdata;
logic [N_CHANNELS-1:0] buf_rctrl;
logic [N_CHANNELS-1:0][W_BYTE-1:0] buf_rdata;
// CRC Signals
logic crc_clr;
logic [N_SYMBOLS-1:0] crc_en;
logic [N_SYMBOLS-1:0][W_SYMBOL-1:0] crc_data;
logic [N_CRC_BYTE-1:0][W_BYTE-1:0] crc;
// --- Main Logic --- //
mac_tx_ctrl u_mac_tx_ctrl(
    .i_clk(i_clk),
    .i_clk_en(i_clk_en),
    .i_reset(i_reset),
    .s_tvalid(s_tvalid),
    .s_tdata(s_tdata),
    .s_tkeep(s_tkeep),
    .s_tlast(s_tlast),
    .s_tready(s_tready),
    .o_hdr_id(hdr_id),
    .o_gen_hdr(gen_hdr),
    .o_gen_data(gen_data),
    .o_gen_idle(gen_idle),
    .o_gen_ifg(gen_ifg),
    .o_gen_error(gen_error),
    .i_buf_empty(buf_empty),
    .o_buf_clear(buf_clear),
    .o_buf_ren(buf_ren),
    .o_buf_wen(buf_wen),
    .o_buf_wctrl(buf_wctrl),
    .o_buf_wdata(buf_wdata),
    .o_crc_clear(crc_clr),
    .o_crc_en(crc_en),
    .o_crc_data(crc_data),
    .i_crc(crc)
);

mac_crc32 u_tx_crc(
    .i_clk(i_clk),
    .i_reset(i_reset),
    .i_clk_en(i_clk_en),
    .i_crc_clr(crc_clr),
    .i_crc_en(crc_en),
    .i_data(crc_data),
    .o_crc(crc)
);

mac_tx_buffer u_mac_tx_buf(
    .i_clk(i_clk),
    .i_clk_en(i_clk_en),
    .i_reset(i_reset),
    .i_clr(buf_clear),
    .i_ren(buf_ren),
    .o_rctrl(buf_rctrl),
    .o_rdata(buf_rdata),
    .o_empty(buf_empty),
    .i_wen(buf_wen),
    .i_wctrl(buf_wctrl),
    .i_wdata(buf_wdata)
);

mac_tx_framegen u_mac_tx_framegen(
    .i_clk(i_clk),
    .i_clk_en(i_clk_en),
    .i_reset(i_reset),
    .i_gen_hdr(gen_hdr),
    .i_hdr_id(hdr_id),
    .i_gen_data(gen_data),
    .i_buf_rctrl(buf_rctrl),
    .i_buf_rdata(buf_rdata),
    .i_gen_idle(gen_idle),
    .i_gen_ifg(gen_ifg),
    .i_gen_error(gen_error),
    .o_xgmii_ctrl(o_xgmii_ctrl),
    .o_xgmii_data(o_xgmii_data)
);

endmodule: mac_tx_top