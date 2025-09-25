module eth_pcs_rx_10g (
    input i_clk,
    input i_reset,
    input [W_DATA-1:0] i_pma_data,
    output o_clk_en,
    output [N_CHANNELS-1:0] o_xgmii_ctrl,
    output [N_CHANNELS-1:0][W_BYTE-1:0] o_xgmii_data
);

// Gearbox wires 
logic grbx_hdr_valid;
logic [W_SYNC-1:0] grbx_hdr;
logic grbx_data_valid;
logic [W_DATA-1:0] grbx_data;

// Gearbox reg wire
logic q_grbx_hdr_valid;
logic [W_SYNC-1:0] q_grbx_hdr;

// Descrambler reg & wires
logic [W_DATA-1:0] d_descr_data, q_descr_data;

assign o_clk_en = grbx_data_valid;

eth_pcs_rx_gearbox
u_rx_gearbox (
    .i_clk(i_clk),
    .i_reset(i_reset),
    .i_pma_data(i_pma_data),
    .o_grbx_hdr_valid(grbx_hdr_valid),
    .o_grbx_hdr(grbx_hdr),
    .o_grbx_data_valid(grbx_data_valid),
    .o_grbx_data(grbx_data)
);

eth_pcs_scrambler #(
    .SCR_MODE(1)
) u_rx_descrambler (
    .i_clk(i_clk),
    .i_reset(i_reset),
    .i_clk_en(o_clk_en), // only descramble valid data
    .i_pld_data(grbx_data),
    .o_scr_data(d_descr_data)
);

always_ff @(posedge i_clk) begin
    if (o_clk_en) begin
        q_grbx_hdr_valid   <= grbx_hdr_valid;
        q_grbx_hdr         <= grbx_hdr;
        q_descr_data       <= d_descr_data;
    end
end 

eth_pcs_66_64_decoder u_pcs_rx_decoder(
    .i_clk(i_clk),
    .i_reset(i_reset),
    .i_clk_en(o_clk_en),
    .i_grbx_hdr_valid(q_grbx_hdr_valid),
    .i_grbx_hdr(q_grbx_hdr),
    .i_descr_data(q_descr_data),
    .o_xgmii_ctrl(o_xgmii_ctrl),
    .o_xgmii_data(o_xgmii_data)
);
    
endmodule : eth_pcs_rx_10g