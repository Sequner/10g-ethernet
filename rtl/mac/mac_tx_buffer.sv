import cmn_params::*;
import mac_params::*;

module mac_tx_buffer(
    input i_clk,
    input i_clk_en,
    input i_reset,
    input i_clr,
    // read ports
    input  logic i_ren,
    output logic [N_CHANNELS-1:0] o_rctrl,
    output logic [N_CHANNELS-1:0][W_BYTE-1:0] o_rdata,
    output logic o_empty,
    // write ports
    input logic i_wen,
    input logic [N_CHANNELS-1:0] i_wctrl,
    input logic [N_CHANNELS-1:0][W_BYTE-1:0] i_wdata
);

// --- Main Logic --- //
logic [N_MAC_TX_BUF-1:0][W_MAC_TX_BUF-1:0] d_buf, q_buf = '0;
logic [W_MAC_TX_BUF_CNT:0] d_rptr, q_rptr; // 1 bit added for wrap around
logic [W_MAC_TX_BUF_CNT:0] d_wptr, q_wptr;
logic [W_MAC_TX_BUF_CNT-1:0] raddr;
logic [W_MAC_TX_BUF_CNT-1:0] waddr;

assign raddr = q_rptr[W_MAC_TX_BUF_CNT-1:0];
assign waddr = q_wptr[W_MAC_TX_BUF_CNT-1:0];
    
always_comb begin : read_port
    d_rptr = q_rptr;
    if (i_clr)
        d_rptr = 0;
    else if (i_ren & !o_empty)
        d_rptr += 1;
end

always_comb begin : write_port
    d_wptr = q_wptr;
    d_buf  = q_buf;
    if (i_clr)
        d_wptr = '0;
    else if (i_wen) begin
        d_buf[waddr][W_DATA+:N_CHANNELS] = i_wctrl;
        d_buf[waddr][W_DATA-1:0] = i_wdata;
        d_wptr += 1;
    end
end

always_ff @(posedge i_clk) begin
    if (i_reset) begin
        q_rptr <= '0;
        q_wptr <= '0;
    end
    else if (i_clk_en) begin
        q_rptr <= d_rptr;
        q_wptr <= d_wptr;
        q_buf <= d_buf;
    end
end

assign o_empty = (q_wptr == q_rptr);

// 4 upper bits of the current line in the buffer
// are valid bits, the rest are data bits
assign o_rctrl = q_buf[raddr][W_DATA+:N_CHANNELS];
assign o_rdata = q_buf[raddr][W_DATA-1:0];

endmodule : mac_tx_buffer