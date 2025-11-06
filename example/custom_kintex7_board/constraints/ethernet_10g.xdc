# maybe change sys_clk period to 50MHz (based on schematic)
create_clock -name sys_clk -period 20 [get_ports i_sys_clk]
set_property PACKAGE_PIN F17 [get_ports i_sys_clk]
set_property IOSTANDARD LVCMOS33 [get_ports i_sys_clk]

create_clock -name ref_clk -period 6.4 [get_ports i_mgtrefclk_p]
set_property PACKAGE_PIN D6 [get_ports i_mgtrefclk_p]
set_property PACKAGE_PIN D5 [get_ports i_mgtrefclk_n]

set_property LOC GTXE2_CHANNEL_X0Y6 [get_cells -hierarchical *gtxe2_i*]

# For CDC
set_false_path -to [get_cells -hierarchical -filter {NAME =~ *data_sync_reg1}]
set_false_path -to [get_cells -hierarchical -filter {NAME =~ *q_rx_byte_received*}]
set_false_path -to [get_cells -hierarchical -filter {NAME =~ *q_rx_last_received*}]

# Improve timing
set_property MAX_FANOUT 32 [get_cells -hierarchical -filter {NAME =~ *u_pcs_tx_gearbox/q_stop_cnt_reg*}]
set_property MAX_FANOUT 64 [get_cells -hierarchical -filter {NAME =~ *u_pcs_rx_decoder/q_trans_cnt_reg*}]

create_pblock pblock_tx
resize_pblock pblock_tx -add {SLICE_X142Y229:SLICE_X145Y230}
#add_cells_to_pblock pblock_tx [get_cells -hierarchical -filter {NAME =~ *q_scr_reg*}]
add_cells_to_pblock pblock_tx [get_cells -hierarchical -filter {NAME =~ *q_pld_blk_reg*}]

#create_pblock pblock_tx_grbx_buf
#resize_pblock pblock_tx_grbx_buf -add {SLICE_X140Y234:SLICE_X143Y236}
#add_cells_to_pblock pblock_tx_grbx_buf [get_cells -hierarchical -filter {NAME =~ *u_pcs_tx_gearbox/q_buf*}]

#create_pblock pblock_inv_sh
#resize_pblock pblock_inv_sh -add {SLICE_X140Y229:SLICE_X145Y230}
#add_cells_to_pblock pblock_inv_sh [get_cells -hierarchical  -filter {NAME =~*sh_cnt*}]

#create_pblock pblock_tx_stop_cnt
#resize_pblock pblock_tx_stop_cnt -add {SLICE_X142Y239:SLICE_X145Y240}
#add_cells_to_pblock pblock_tx_stop_cnt [get_cells -hierarchical -filter {NAME =~ *u_pcs_tx_gearbox/q_stop_cnt*}]

#create_pblock pblock_inv_sh_cnt
#resize_pblock pblock_inv_sh_cnt -add {SLICE_X142Y228:SLICE_X145Y229}
#add_cells_to_pblock pblock_inv_sh_cnt [get_cells -hierarchical  -filter {NAME =~*sh_inval_cnt*}]
