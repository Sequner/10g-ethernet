import mac_params::*;

module mac_tx_framegen(
    input i_clk,
    input i_clk_en,
    input i_reset,
    // HDR signals
    input logic i_gen_hdr,
    input logic [W_MAC_HDR_CNT-1:0] i_hdr_id,
    // Data signals
    input logic i_gen_data,
    input logic [N_CHANNELS-1:0] i_buf_rctrl,
    input logic [N_CHANNELS-1:0][W_BYTE-1:0] i_buf_rdata,
    // Idle signal
    input logic i_gen_idle,
    // Inter-frame gap signal
    input logic i_gen_ifg,
    // Error signal
    input logic i_gen_error,
    output logic [N_CHANNELS-1:0] o_xgmii_ctrl,
    output logic [N_CHANNELS-1:0][W_BYTE-1:0] o_xgmii_data
);

// --- Functions --- ///
// Header Generator
function automatic void send_header(
    input  [W_MAC_HDR_CNT-1:0]          i_hdr_cnt,
    output [N_CHANNELS-1:0]             o_xgmii_ctrl,
    output [N_CHANNELS-1:0][W_BYTE-1:0] o_xgmii_data
);
    o_xgmii_ctrl = MAC_HDR_CTRL[N_CHANNELS*i_hdr_cnt+:N_CHANNELS];
    o_xgmii_data = MAC_HDR_DATA[W_DATA*i_hdr_cnt+:W_DATA];
endfunction

// TODO: think about prediction-based error gen
// Error Generator
function automatic void send_err(
    output [N_CHANNELS-1:0]             o_xgmii_ctrl,
    output [N_CHANNELS-1:0][W_BYTE-1:0] o_xgmii_data
);
    o_xgmii_ctrl = '1;
    o_xgmii_data = {N_SYMBOLS{SYM_IDLE}};
    o_xgmii_data[0] = SYM_ERR;
endfunction

// Send data from buffer to XGMII
function automatic void send_data(
    input  [N_CHANNELS-1:0] i_ctrl,
    input  [N_CHANNELS-1:0][W_BYTE-1:0] i_data,
    output [N_CHANNELS-1:0]             o_xgmii_ctrl,
    output [N_CHANNELS-1:0][W_BYTE-1:0] o_xgmii_data
);
    o_xgmii_ctrl = i_ctrl;
    o_xgmii_data = i_data;
endfunction

// Send idle
function automatic void send_idle(
    output [N_CHANNELS-1:0]             o_xgmii_ctrl,
    output [N_CHANNELS-1:0][W_BYTE-1:0] o_xgmii_data
);
    o_xgmii_ctrl = '1;
    o_xgmii_data = {N_CHANNELS{SYM_IDLE}};
endfunction

logic [N_CHANNELS-1:0] d_xgmii_ctrl;
logic [N_CHANNELS-1:0] q_xgmii_ctrl = '1;
logic [N_CHANNELS-1:0][W_BYTE-1:0] d_xgmii_data;
logic [N_CHANNELS-1:0][W_BYTE-1:0] q_xgmii_data = {N_CHANNELS{SYM_IDLE}};
always_comb begin
    d_xgmii_ctrl = '1;
    d_xgmii_data = {N_CHANNELS{SYM_IDLE}};

    if (i_gen_hdr)
        send_header(i_hdr_id, 
                    d_xgmii_ctrl,
                    d_xgmii_data);
    else if (i_gen_error)
        send_err(d_xgmii_ctrl,
                 d_xgmii_data);
    else if (i_gen_data)
        send_data(i_buf_rctrl,
                  i_buf_rdata,
                  d_xgmii_ctrl,
                  d_xgmii_data);
    else if (i_gen_idle | i_gen_ifg)
        send_idle(d_xgmii_ctrl,
                  d_xgmii_data);
end

always_ff @(posedge i_clk) begin : reg_ctrl
    if (i_clk_en) begin
        q_xgmii_ctrl <= d_xgmii_ctrl;
        q_xgmii_data <= d_xgmii_data;
    end
end

assign o_xgmii_ctrl = q_xgmii_ctrl;
assign o_xgmii_data = q_xgmii_data;

endmodule