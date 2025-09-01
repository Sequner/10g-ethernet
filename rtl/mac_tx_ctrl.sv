import cmn_params::*;
import mac_params::*;

module mac_tx_ctrl(
    input i_clk,
    input i_clk_en,
    input i_reset,
    // AXI-Stream Slave Interface
    input  logic s_tvalid,
    input  logic [N_SYMBOLS-1:0][W_SYMBOL-1:0] s_tdata,
    input  logic [N_SYMBOLS-1:0] s_tkeep,
    input  logic s_tlast,
    output logic s_tready,
    // Framegen Ctrl
    output logic [W_MAC_HDR_CNT-1:0] o_hdr_id,
    output logic o_gen_hdr,
    output logic o_gen_data,
    output logic o_gen_idle,
    output logic o_gen_ifg,
    output logic o_gen_error,
    // Buffer Ctrl
    input  logic i_buf_empty,
    output logic o_buf_clear,
    output logic o_buf_ren, // data is read by framegen
    output logic o_buf_wen,
    output logic [N_CHANNELS-1:0] o_buf_wctrl,
    output logic [N_CHANNELS-1:0][W_BYTE-1:0] o_buf_wdata,
    // CRC Ctrl
    output logic o_crc_clear,
    output logic [N_SYMBOLS-1:0] o_crc_en,
    output logic [N_SYMBOLS-1:0][W_SYMBOL-1:0] o_crc_data, 
    input  logic [N_CRC_BYTE-1:0][W_BYTE-1:0] i_crc
);

`define ONE_HOT(n) (1 << (n))
localparam N_STATE = 9;
typedef enum logic [N_STATE-1:0] {
    ST_INIT     = `ONE_HOT(0),
    ST_WAIT_HDR = `ONE_HOT(1),
    ST_DATA     = `ONE_HOT(2),
    ST_TAIL     = `ONE_HOT(3),
    ST_PAD      = `ONE_HOT(4),
    ST_CRC      = `ONE_HOT(5),
    ST_TERM     = `ONE_HOT(6),
    ST_WAIT_IFG = `ONE_HOT(7),
    ST_ERROR    = `ONE_HOT(8)
} state_t;

// FSM state
state_t d_state; 
state_t q_state = ST_INIT;
// AXI-S Ready ctrl
logic d_tready, q_tready;
// Type of received data through AXI-S I/F
logic term_rcvd;
logic data_rcvd;
logic error_rcvd;
// Track current part of the 64B block being generated
logic [W_TRANS_PER_BLK-1:0] d_trans_id, q_trans_id;
// Show which HDR part to generate
logic [W_MAC_HDR_CNT-1:0] d_hdr_id, q_hdr_id;
// Min PLD counter - counts the number of full transactions
// where data_valid/tkeep is all ones
logic [W_MIN_TRANS:0] d_pld_cnt, q_pld_cnt;
// Save tlast data
logic q_last_rcvd;
logic [N_SYMBOLS-1:0] d_last_valid, q_last_valid;
logic [N_SYMBOLS-1:0][W_SYMBOL-1:0] d_last_data, q_last_data;
// Data tail & pad Gen
logic wr_pad_tail;
logic wr_crc_tail;
logic wr_pad;
// CRC Gen
logic wr_crc;
logic [$clog2(N_CRC_BYTE):0] d_crc_id, q_crc_id;
// Termination Gen
logic wr_term;
// IFG Gen
logic [$clog2(N_IFG_TRANS-1):0] d_ifg_cnt, q_ifg_cnt;
// Reset counter states
logic reset_states;

always_comb begin : axis2ctrl_converter
    logic [$clog2(N_SYMBOLS)-1:0] id;
    id = 0;
    d_last_valid = q_last_valid;
    d_last_data  = q_last_data;

    term_rcvd = '0;
    data_rcvd = '0;
    error_rcvd  = '0;
    // valid transaction
    if (s_tvalid & s_tready) begin // TODO: try with unique if
        if (s_tlast & |s_tkeep) begin
            term_rcvd = 1'b1;
            d_last_valid = '0;
            d_last_data = '0;
            // grouping all valid symbols together
            for (int i=0; i<N_SYMBOLS; i++) begin
                // TODO: group all tkeep[i] == 1
                if (s_tkeep[i]) begin
                    d_last_valid[id] = s_tkeep[i];
                    d_last_data[id]  = s_tdata[i];
                    id += 1;
                end
            end
        end
        else if (s_tkeep == '1) // all 1s
            data_rcvd = 1'b1;
        else 
            error_rcvd = 1'b1;
    end
    else if (!s_tvalid & s_tready & (q_state != ST_INIT))
        error_rcvd = 1'b1;
end

// Which part of 64B is generated
always_comb begin : trans_id_ctrl
// TODO: set offset for trans_id to control
//       which part is currently being sent after reset
    d_trans_id = q_trans_id;
    d_trans_id += 1;
end

// Show which HDR part to generate
always_comb begin : hdr_id_ctrl
    d_hdr_id = q_hdr_id;
    if (reset_states)
        d_hdr_id = '0;
    else if (o_gen_hdr)
        d_hdr_id += 1;
end

// Every full transaction (data_rcvd) increment by 1
// at term_rcvd, add CRC with tkeep value
always_comb begin : pld_cnt_ctrl
    d_pld_cnt = q_pld_cnt;

    // reset during error
    if (reset_states) // TODO: try with unique if
        d_pld_cnt = '0;
    else if (d_pld_cnt < N_MIN_TRANS) begin
        if (data_rcvd) begin // TODO: try with unique if
            d_pld_cnt += 1;
        end
        else if (term_rcvd) begin
            // W_CRC / W_DATA is the # of transactions it takes
            // to transfer full CRC32
            d_pld_cnt += W_CRC/W_DATA + (s_tkeep == '1);
        end
        else if (wr_pad_tail | wr_pad) begin
            d_pld_cnt += 1;
        end 
    end
end

always_comb begin : ifg_ctrl
    d_ifg_cnt = q_ifg_cnt;
    if (s_tready)
        d_ifg_cnt = '0;
    else if (o_gen_ifg)
        d_ifg_cnt += 1;
end

always_comb begin : buf_ctrl
    logic term;
    term = 1'b1;

    d_crc_id = q_crc_id;
    o_buf_clear = '0;
    o_buf_ren = o_gen_data;
    o_buf_wen = (data_rcvd)   | 
                (wr_pad_tail) |
                (wr_crc_tail) |
                (wr_pad)      |
                (wr_crc)      |
                (wr_term)     ;

    o_buf_wctrl = '0;
    o_buf_wdata = s_tdata;
    if (reset_states) begin // TODO: do with unique if
        o_buf_clear = 1'b1;
        d_crc_id = '0;
    end
    else if (wr_pad_tail) begin
        for (int i=0; i<N_CHANNELS; i++) begin
            if (q_last_valid[i])
                o_buf_wdata[i] = q_last_data[i];
            else
                o_buf_wdata[i] = '0;
        end
    end
    else if (wr_crc_tail) begin
        for (int i=0; i<N_CHANNELS; i++) begin
            if (q_last_valid[i])
                o_buf_wdata[i] = q_last_data[i];
            else begin
                o_buf_wdata[i] = i_crc[d_crc_id];
                d_crc_id += 1;
            end
        end
    end
    else if (wr_pad) begin
        o_buf_wdata = '0;
    end
    else if (wr_crc) begin
        o_buf_wdata = i_crc[d_crc_id+:N_CHANNELS];
        d_crc_id += N_CHANNELS;
    end
    else if (wr_term) begin // TODO: if crit. path, modify
        o_buf_wctrl = '1;
        o_buf_wdata = {N_CHANNELS{SYM_IDLE}};
        for (int i=0; i<N_CHANNELS; i++) begin
            if (d_crc_id < N_CRC_BYTE) begin
                o_buf_wctrl[i] = 1'b0;
                o_buf_wdata[i] = i_crc[d_crc_id];
                d_crc_id += 1;
            end
            else if (term) begin
                o_buf_wdata[i] = SYM_TERM;
                term = 1'b0;
            end
        end
    end
end

always_comb begin : crc_ctrl
// TODO: for 644 MHz, pipeline AXI-Stream
    o_crc_clear = reset_states; // reset on error
    o_crc_en = '0;
    o_crc_data = '0;

    if (data_rcvd | term_rcvd) begin // TODO: try with unique if
        o_crc_en   = s_tkeep;
        o_crc_data = s_tdata;
    end
    else if (wr_pad_tail) begin
        o_crc_en   = ~d_last_valid;
        o_crc_data = '0;
    end
    else if (wr_pad) begin
        o_crc_en   = '1;
        o_crc_data = '0;
    end
end

always_comb begin : fsm_ctrl
    d_state = q_state;

    o_hdr_id    = q_hdr_id;
    o_gen_hdr   = '0;
    o_gen_data  = '0;
    o_gen_idle  = '0;
    o_gen_error = '0;
    o_gen_ifg   = '0;

    wr_pad_tail = '0;
    wr_crc_tail = '0;
    wr_pad      = '0;
    wr_crc      = '0;
    wr_term     = '0;

    reset_states = '0;
    unique case (q_state)
        ST_INIT: begin
            // TODO: add start at 0th and 4th byte support
            // by turning the ready signal on and off
            if (!data_rcvd & !term_rcvd)
                o_gen_idle = 1'b1;
            else begin
                o_gen_hdr = 1'b1;
                d_state = ST_WAIT_HDR;
            end
        end 
        ST_WAIT_HDR: begin
            if (error_rcvd) begin
                d_state = ST_ERROR;
                o_gen_error = 1'b1;
            end
            else begin
                o_gen_hdr = 1'b1;
                if (q_hdr_id == MAC_HDR_CNT-1)
                    d_state = ST_DATA;
            end
        end
        ST_DATA: begin
            if (error_rcvd) begin
                d_state = ST_ERROR;
                o_gen_error = 1'b1;
            end
            else begin
                o_gen_data = 1'b1;
                // s_tlast was received
                if (!q_tready | term_rcvd)
                    d_state = ST_TAIL;
            end
        end
        ST_TAIL: begin
            o_gen_data = 1'b1;
            if (q_pld_cnt < N_MIN_TRANS) begin
                wr_pad_tail = 1'b1;
                // after last data is sent,
                // we will have enough PLDs
                if (q_pld_cnt == N_MIN_TRANS-1)
                    d_state = ST_CRC;
                else
                    d_state = ST_PAD;
            end
            else begin
                wr_crc_tail = 1'b1;
                if (W_DATA == 32)
                    d_state = ST_TERM;
                else
                    d_state = ST_CRC;
            end
        end
        ST_PAD: begin
            o_gen_data = 1'b1;
            wr_pad = 1'b1;
            d_state = ST_CRC;
        end
        ST_CRC: begin
            o_gen_data = 1'b1;
            wr_crc = 1'b1;
            if (q_crc_id != 0)
                d_state = ST_TERM;
        end
        ST_TERM: begin
            o_gen_data = 1'b1;
            wr_term = 1'b1;
            d_state = ST_WAIT_IFG;
        end
        ST_WAIT_IFG: begin
            if (i_buf_empty) begin
                o_gen_ifg = 1'b1;
                if (q_ifg_cnt == N_IFG_TRANS-1) begin
                    reset_states = 1'b1;
                    d_state = ST_INIT;
                end
            end
            else
                o_gen_data = 1'b1;
        end
        ST_ERROR : begin
            o_gen_idle = 1'b1;
            if (q_trans_id == N_TRANS_PER_BLK-1) begin
                reset_states = 1'b1;
                d_state = ST_INIT;
            end
        end
    endcase
end

always_ff @(posedge i_clk) begin : reg_ctrl
    if (i_reset) begin
        q_state <= ST_INIT;
        q_tready <= 1'b1;
        q_trans_id <= '0; // TODO: set offset
        q_hdr_id <= '0; 
        q_last_valid <= '0;
        q_last_data <= '0;
        q_pld_cnt <= '0;
        q_crc_id <= '0;
        q_ifg_cnt <= '0;
        q_last_rcvd <= '0;
    end
    else if (i_clk_en) begin
        q_state  <= d_state;
        q_trans_id <= d_trans_id;
        q_hdr_id <= d_hdr_id;
        q_last_valid <= d_last_valid;
        q_last_data  <= d_last_data;
        q_pld_cnt <= d_pld_cnt;
        q_crc_id  <= d_crc_id;
        q_ifg_cnt <= d_ifg_cnt;
        if (term_rcvd | error_rcvd)
            q_tready <= 1'b0;
        else if (reset_states)
            q_tready <= 1'b1;
    end
end

assign s_tready = (i_clk_en) ? q_tready : 0;

endmodule : mac_tx_ctrl