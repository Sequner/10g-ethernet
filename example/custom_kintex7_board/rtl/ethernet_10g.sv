`timescale 1ns/1ps

import cmn_params::*;
import mac_params::*;
import eth_pcs_params::*;

module ethernet_10g (
    // System clock
    input i_sys_clk,
    input i_sys_reset,
    // Reference clock
    input i_mgtrefclk_p,
    input i_mgtrefclk_n,
    // TX MAC-PCS clk
    output o_tx_clk,
    // TX gtx transceiver serial output
    output o_gtx_txp,
    output o_gtx_txn,
    // TX Slave AXI-Stream Interface
    input s_axis_tvalid,
    input [N_SYMBOLS-1:0][W_SYMBOL-1:0] s_axis_tdata,
    input [N_SYMBOLS-1:0] s_axis_tkeep,
    input s_axis_tlast,
    output s_axis_tready,
    // RX MAC-PCS clk
    output o_rx_clk,
    // RX gtx transceiver serial input
    input i_gtx_rxp,
    input i_gtx_rxn,
    // RX Master AXI-Stream Interface
    output m_axis_tvalid,
    output [N_SYMBOLS-1:0] m_axis_tkeep,
    output [N_SYMBOLS-1:0][W_SYMBOL-1:0] m_axis_tdata,
    output m_axis_tlast,
    output m_axis_tuser,
    // Transceiver Loopback Mode
    // https://docs.amd.com/r/en-US/pg168-gtwizard/Loopback-Mode-Testing
    input [2:0] i_gtx_loopback,
    // Transceiver RX Reset - for loopback
    input i_gtx_rx_reset
);

// Transceiver wires 
logic tx_clk;
logic rx_clk;
logic tx_reset_done;
logic rx_reset_done;
logic [W_DATA-1:0] tx_pma_data;
logic [W_DATA-1:0] rx_pma_data;
// Synchronized reset
logic sync_tx_reset_done;
logic sync_rx_reset_done;

custom_mac_pcs u_mac_pcs (
    // TX Clock & Reset
    .i_tx_clk(tx_clk),
    .i_tx_reset(~sync_tx_reset_done),
    // TX AXIS Slave
    .s_axis_tvalid,
    .s_axis_tdata,
    .s_axis_tkeep,
    .s_axis_tlast,
    .s_axis_tready,
    // TX PMA
    .o_tx_pma_data(tx_pma_data),
    // RX Clock & Reset
    .i_rx_clk(rx_clk),
    .i_rx_reset(~sync_rx_reset_done),
    // RX AXIS Master
    .m_axis_tvalid,
    .m_axis_tkeep,
    .m_axis_tdata,
    .m_axis_tlast,
    .m_axis_tuser,
    // RX PMA
    .i_rx_pma_data(rx_pma_data)
);

// sys_clk -> tx_clk
gtwizard_pma_sync_block u_sync_tx_reset_done (
    .clk     (tx_clk),
    .data_in (tx_reset_done),
    .data_out(sync_tx_reset_done)
);

// sys_clk -> rx_clk
gtwizard_pma_sync_block u_sync_rx_reset_done (
    .clk     (rx_clk),
    .data_in (rx_reset_done),
    .data_out(sync_rx_reset_done)
);

gtwizard_pma u_pma (
    .soft_reset_tx_in(i_sys_reset),
    .soft_reset_rx_in(i_sys_reset),
    .dont_reset_on_data_error_in('0),
    .q1_clk0_gtrefclk_pad_n_in(i_mgtrefclk_n),
    .q1_clk0_gtrefclk_pad_p_in(i_mgtrefclk_p),
    .gt0_tx_mmcm_lock_out(),
    .gt0_tx_fsm_reset_done_out(tx_reset_done),
    .gt0_rx_fsm_reset_done_out(rx_reset_done),
    .gt0_data_valid_in(1'b1),
    .gt0_txusrclk_out(),
    .gt0_txusrclk2_out(tx_clk),
    .gt0_rxusrclk_out(),
    .gt0_rxusrclk2_out(rx_clk),
    //_________________________________________________________________________
    //GT0  (X1Y0)
    //____________________________CHANNEL PORTS________________________________
    //-------------------------- Channel - DRP Ports  --------------------------
    .gt0_drpaddr_in('0),
    .gt0_drpdi_in('0),
    .gt0_drpdo_out(),
    .gt0_drpen_in('0),
    .gt0_drprdy_out(),
    .gt0_drpwe_in('0),
    //------------------------- Digital Monitor Ports --------------------------
    .gt0_dmonitorout_out(),
    //----------------------------- Loopback Ports -----------------------------
    .gt0_loopback_in(i_gtx_loopback),
    //------------------- RX Initialization and Reset Ports --------------------
    .gt0_eyescanreset_in('0),
    .gt0_rxuserrdy_in(1'b1),
    //------------------------ RX Margin Analysis Ports ------------------------
    .gt0_eyescandataerror_out(),
    .gt0_eyescantrigger_in('0),
    //---------------- Receive Ports - FPGA RX interface Ports -----------------
    .gt0_rxdata_out(rx_pma_data),
    //------------------------- Receive Ports - RX AFE -------------------------
    .gt0_gtxrxp_in(i_gtx_rxp),
    //---------------------- Receive Ports - RX AFE Ports ----------------------
    .gt0_gtxrxn_in(i_gtx_rxn),
    //----------------- Receive Ports - RX Buffer Bypass Ports -----------------
    .gt0_rxphmonitor_out(),
    .gt0_rxphslipmonitor_out(),
    //------------------- Receive Ports - RX Equalizer Ports -------------------
    .gt0_rxdfelpmreset_in('0),
    .gt0_rxmonitorout_out(),
    .gt0_rxmonitorsel_in('0),
    //------------- Receive Ports - RX Fabric Output Control Ports -------------
    .gt0_rxoutclkfabric_out(),
    //----------- Receive Ports - RX Initialization and Reset Ports ------------
    .gt0_gtrxreset_in(i_gtx_rx_reset),
    .gt0_rxpmareset_in(),
    //------------ Receive Ports -RX Initialization and Reset Ports ------------
    .gt0_rxresetdone_out(),
    //------------------- TX Initialization and Reset Ports --------------------
    .gt0_gttxreset_in('0),
    .gt0_txuserrdy_in(1'b1),
    //---------------- Transmit Ports - TX Data Path interface -----------------
    .gt0_txdata_in(tx_pma_data),
    //-------------- Transmit Ports - TX Driver and OOB signaling --------------
    .gt0_gtxtxn_out(o_gtx_txn),
    .gt0_gtxtxp_out(o_gtx_txp),
    //--------- Transmit Ports - TX Fabric Clock Output Control Ports ----------
    .gt0_txoutclkfabric_out(),
    .gt0_txoutclkpcs_out(),
    //----------- Transmit Ports - TX Initialization and Reset Ports -----------
    .gt0_txresetdone_out(),
    //____________________________COMMON PORTS________________________________
    .gt0_qplllock_out(),
    .gt0_qpllrefclklost_out(),
    .gt0_qplloutclk_out(),
    .gt0_qplloutrefclk_out(),
    .sysclk_in(i_sys_clk)
);

assign o_tx_clk = tx_clk;
assign o_rx_clk = rx_clk;

endmodule : ethernet_10g