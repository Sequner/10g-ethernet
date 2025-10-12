import mac_params::*;

module mac_rx (
    input i_clk,
    input i_reset,
    input i_clk_en,
    // XGMII Interface
    input [N_CHANNELS-1:0] i_xgmii_ctrl,
    input [N_CHANNELS-1:0][W_BYTE-1:0] i_xgmii_data,
    // AXI-Stream Interface
    output logic m_axis_tvalid,
    output logic [N_SYMBOLS-1:0] m_axis_tkeep,
    output logic [N_SYMBOLS-1:0][W_SYMBOL-1:0] m_axis_tdata,
    output logic m_axis_tlast,
    output logic m_axis_tuser
);

function check_hdr(
    input [N_CHANNELS-1:0] i_xgmii_ctrl,
    input [N_CHANNELS-1:0][W_BYTE-1:0] i_xgmii_data,
    input [W_TRANS_PER_BLK-1:0] i_hdr_cnt
);
    check_hdr = (MAC_HDR_CTRL[i_hdr_cnt*N_CHANNELS+:N_CHANNELS] == 
                 i_xgmii_ctrl) & 
                (MAC_HDR_DATA[i_hdr_cnt*W_DATA+:W_DATA] == 
                 i_xgmii_data);
endfunction

`define ONE_HOT(n) (1 << (n))
typedef enum logic [4:0] {
    ST_INIT = `ONE_HOT(0),
    ST_HDR  = `ONE_HOT(1),
    ST_DATA = `ONE_HOT(2),
    ST_TERM = `ONE_HOT(3),
    ST_CRC  = `ONE_HOT(4)
} state_t;

// FSM State
state_t d_state;
state_t q_state = ST_INIT;
// PLD count ctrl
logic [W_MIN_TRANS:0] d_pld_cnt, q_pld_cnt;
logic d_min_pld_error, q_min_pld_error;
// Current hdr id
logic [W_MAC_HDR_CNT-1:0] d_hdr_cnt, q_hdr_cnt;
logic [W_MAC_HDR_CNT-1:0] hdr_id;
// Input controls from PCS
logic error_rcvd;
logic data_rcvd;
logic hdr_rcvd;
logic term_rcvd;
logic [W_BYTES_PER_BLK-1:0] num_term_data;
logic q_small_term; // terminate block with less than 4 valid data
// Output controls
logic send_axis_data;
logic send_axis_eof;
logic send_axis_error;
// CRC logic 
logic crc_clear;
logic [W_CRC-1:0] crc;

always_comb begin : key_ctrl
    // it's enough to check first symbol
    error_rcvd = (i_xgmii_ctrl[0] == 1'b1) &
                 (i_xgmii_data[0] == SYM_ERR);
    // all channels are data symbols
    data_rcvd  = (i_xgmii_ctrl == '0);
    // last channel is a control symbol is a customized (non-spec)
    // term symbol for RX-side MAC. See 66_64_decoder code
    term_rcvd  = (i_xgmii_ctrl == (1<<(N_CHANNELS-1)));
    num_term_data = i_xgmii_data[N_CHANNELS-1]; 
    // checks if received data belongs to header
    hdr_rcvd = check_hdr(i_xgmii_ctrl, i_xgmii_data, hdr_id); 
end

always_comb begin : fsm_ctrl
    d_state = q_state;
    d_hdr_cnt = q_hdr_cnt;
    d_pld_cnt = q_pld_cnt;
    d_min_pld_error = '0;

    // when init, check 0th id of hdr
    hdr_id = (q_state == ST_INIT) ? '0 : q_hdr_cnt; 
    crc_clear = '0;
    send_axis_data = '0;
    send_axis_eof = '0;
    send_axis_error = '0;

    unique case (q_state)
        ST_INIT: begin
            d_hdr_cnt = 1'b1; // reset hdr cnt
            crc_clear = 1'b1;
            if (hdr_rcvd) begin
                d_state = ST_HDR;
            end
        end
        ST_HDR: begin
            if (hdr_rcvd) begin
                if (q_hdr_cnt == '1)
                    d_state = ST_DATA;
                d_hdr_cnt += 1'b1;
            end
            // hdr must be received consequtively
            // otherwise, it's an error
            else begin
                d_state = ST_INIT;
            end
        end
        ST_DATA: begin
            send_axis_data = data_rcvd | term_rcvd; 
            unique if (data_rcvd)
                d_pld_cnt += 1'b1;
            else if (term_rcvd) begin
                d_pld_cnt += num_term_data / N_BYTES_PER_TRANS;
                d_min_pld_error = (d_pld_cnt < N_MIN_PLD);
                // only N_CHANNEL-1 bytes of data are received this cycle
                // {ctrl, data, data, data} in case of W_DATA==32
                // so if term block has more, they will arrive on the next cycle
                if (num_term_data > N_CHANNELS-1)
                    d_state = ST_TERM;
                else
                    d_state = ST_CRC;
            end
            // in case non-data and non-term data is received
            // it is an error (not checking error_rcvd for timing)
            else begin
                d_state = ST_INIT;
                send_axis_error = 1'b1;
            end
        end
        ST_TERM: begin
            send_axis_data = 1'b1;
            // PCS sends the first half of the 64B block
            // assuming the second half will be received properly
            // ST_TERM is checking if the second half is correct
            if (error_rcvd) begin
                d_state = ST_INIT;
                send_axis_error = 1'b1;
            end
            else begin
                d_state = ST_CRC;
            end
        end
        ST_CRC: begin
            d_state = ST_INIT;
            send_axis_error = (q_small_term & error_rcvd) |
                              (q_min_pld_error) |
                              (crc != CRC_MAGIC_NUM);
            send_axis_eof = 1'b1;
        end
    endcase
end

always_comb begin : output_ctrl
    m_axis_tvalid = (send_axis_data | send_axis_error | send_axis_eof) & i_clk_en;
    m_axis_tdata  = i_xgmii_data;
    m_axis_tkeep  = ~i_xgmii_ctrl; // data symbols are 1, ctrl symbols are 0
    m_axis_tlast  = send_axis_eof; 
    m_axis_tuser  = ~send_axis_error;
end

always_ff @(posedge i_clk) begin : ff_ctrl
    if (i_clk_en) begin
        q_state <= d_state;
        q_small_term <= (num_term_data == '0);
        q_pld_cnt <= d_pld_cnt;
        q_min_pld_error <= d_min_pld_error;
        q_hdr_cnt <= d_hdr_cnt;
    end
end

mac_crc32 u_rx_crc32(
    .i_clk(i_clk),
    .i_reset(i_reset),
    .i_clk_en(i_clk_en),
    .i_crc_clr(crc_clear),
    .i_crc_en({N_CHANNELS{send_axis_data}} & m_axis_tkeep),
    .i_data(m_axis_tdata),
    .o_crc(crc)
);
    
endmodule : mac_rx