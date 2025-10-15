import cmn_params::*;
import mac_params::*;

module mac_tx_ctrl(
    input i_clk,
    input i_clk_en,
    input i_reset,
    // AXI-Stream Slave Interface
    input  logic s_axis_tvalid,
    input  logic [N_SYMBOLS-1:0] s_axis_tkeep,
    input  logic [N_SYMBOLS-1:0][W_SYMBOL-1:0] s_axis_tdata,
    input  logic s_axis_tlast,
    output logic s_axis_tready,
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
    ST_WAIT_IFG = `ONE_HOT(7)
} state_t;

// FSM State
state_t d_state; 
state_t q_state = ST_INIT;
// AXI-S Ready ctrl
logic d_tready; 
logic q_tready = 1'b0;
// Type of received data through AXI-S I/F
logic term_rcvd;
logic data_rcvd;
// Track current part of the 64B block being generated
logic [W_TRANS_PER_BLK-1:0] d_trans_id;
logic [W_TRANS_PER_BLK-1:0] q_trans_id = INIT_MAC_TRANS_ID;
// Show which HDR part to generate
logic [W_MAC_HDR_CNT-1:0] d_hdr_id, q_hdr_id = '0;
// Min PLD counter - counts the number of full transactions
// where data_valid/tkeep is all ones
logic [W_MIN_TRANS:0] d_pld_cnt;
logic [W_MIN_TRANS:0] q_pld_cnt = INIT_MIN_PLD_CNT;
// Save tlast data
logic [N_SYMBOLS-1:0] d_last_valid, q_last_valid = '0;
logic [N_SYMBOLS-1:0][W_SYMBOL-1:0] d_last_data, q_last_data = '0;
// Data tail & pad Gen
logic wr_tail_pad;
logic wr_tail_crc;
logic wr_pad;
// CRC Gen
logic wr_crc;
logic [$clog2(N_CRC_BYTE):0] d_crc_id, q_crc_id = '0;
// Termination Gen
logic wr_term;
// IFG Gen
logic [$clog2(N_IFG_TRANS-1):0] d_ifg_cnt, q_ifg_cnt = '0;
// Reset counter states
logic reset_states;

always_comb begin : axis2ctrl_converter
    term_rcvd = '0;
    data_rcvd = '0;
    // valid transaction
    if (s_axis_tvalid & q_tready) begin
        if (s_axis_tlast) begin
            term_rcvd = 1'b1;
            assert(s_axis_tkeep == 0  |
                   s_axis_tkeep == 1  | s_axis_tkeep == 3  |
                   s_axis_tkeep == 7  | s_axis_tkeep == 15 |
                   s_axis_tkeep == 23 | s_axis_tkeep == 31 )
            else $fatal("transaction is not aligned properly");
        end
        else begin
            data_rcvd = 1'b1;
            assert(s_axis_tkeep == '1)
            else $fatal("transaction is not aligned properly");
        end
    end
end

// Which part of 64B is generated
always_comb begin : trans_id_ctrl
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
always_comb begin : pld_cnt_ctrl
    d_pld_cnt = q_pld_cnt;
    // reset during error
    if (reset_states) // TODO: try with unique if
        d_pld_cnt = INIT_MIN_PLD_CNT;
    // increment by 1 only if q_cld_cnt less than N_MIN_TRANS
    else if (data_rcvd | wr_tail_pad | wr_pad) 
        d_pld_cnt += (q_pld_cnt < N_MIN_TRANS);
end

always_comb begin : ifg_ctrl
    d_ifg_cnt = q_ifg_cnt;
    if (q_tready)
        d_ifg_cnt = '0;
    else if (o_gen_ifg)
        d_ifg_cnt += 1;
end

always_comb begin : last_valid_ctrl
    // Zero out invalid bytes
    for (int i=0; i<N_SYMBOLS; i++) begin
        if (!s_axis_tkeep[i])
            d_last_data[i] = '0; 
        else
            d_last_data[i] = s_axis_tdata[i];
    end

    if (term_rcvd & q_pld_cnt < N_MIN_TRANS)
        d_last_valid = '1;
    else
        d_last_valid = s_axis_tkeep;
end

always_comb begin : buf_ctrl
    logic term;
    term = 1'b1;

    d_crc_id = q_crc_id;
    o_buf_clear = '0;
    o_buf_ren = o_gen_data;
    o_buf_wen = (data_rcvd)   | 
                (wr_tail_pad) |
                (wr_tail_crc) |
                (wr_pad)      |
                (wr_crc)      |
                (wr_term)     ;

    o_buf_wctrl = '0;
    o_buf_wdata = s_axis_tdata;
    if (reset_states) begin // TODO: do with unique if
        o_buf_clear = 1'b1; // not needed actually
        d_crc_id = '0;
    end
    else if (wr_tail_pad) begin
        o_buf_wctrl = '0;
        o_buf_wdata = q_last_data;
    end
    else if (wr_tail_crc) begin
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

    if (data_rcvd) begin
        o_crc_en   = s_axis_tkeep;
        o_crc_data = s_axis_tdata;
    end
    // if min pld requirement is satisfied
    else if (term_rcvd & q_pld_cnt >= N_MIN_PLD) begin
        o_crc_en   = s_axis_tkeep;
        o_crc_data = s_axis_tdata;
    end
    else if (wr_tail_pad) begin
        o_crc_en   = q_last_valid;
        o_crc_data = q_last_data;
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

    wr_tail_pad = '0;
    wr_tail_crc = '0;
    wr_pad      = '0;
    wr_crc      = '0;
    wr_term     = '0;

    reset_states = '0;
    unique case (q_state)
        ST_INIT: begin
            // TODO: add start at 0th and 4th byte support
            // by turning the ready signal on and off (for W_DATA==16)
            if (!data_rcvd & !term_rcvd) begin
                o_gen_idle = 1'b1;
                reset_states = 1'b1;
            end
            else begin
                o_gen_hdr = 1'b1;
                d_state = ST_WAIT_HDR;
            end
        end 
        ST_WAIT_HDR: begin
            o_gen_hdr = 1'b1;
            if (q_hdr_id == MAC_HDR_CNT-1) begin
                // in case term was received in the very 1st
                // transaction, the data is saved in
                // q_last_data register, which is sent during ST_TAIL
                if (!i_buf_empty)
                    d_state = ST_DATA;
                else
                    d_state = ST_TAIL;
            end
        end
        ST_DATA: begin
            // !q_tready means term has already been received
            o_gen_data = 1'b1;
            if (term_rcvd | !q_tready)
                d_state = ST_TAIL;
            // if term is not rcvd and data is not received
            // it's an error. Data must be sent continuously
            else begin
                assert(data_rcvd)
                else begin
                    $fatal("data transmission stopped without tlast");
                end
            end
        end
        ST_TAIL: begin
            o_gen_data = 1'b1;
            if (q_pld_cnt < N_MIN_TRANS) begin
                wr_tail_pad = 1'b1;
                // after last data is sent,
                // we will have enough PLDs
                if (q_pld_cnt == N_MIN_TRANS-1)
                    d_state = ST_CRC;
                else
                    d_state = ST_PAD;
            end
            else begin
                wr_tail_crc = 1'b1;
                if (W_DATA == 32) begin
                    // whole 32 bits of CRC have to be sent
                    // on the next clock cycle
                    if (q_last_valid == '1)
                        d_state = ST_CRC;
                    // at least 8 bits of CRC are sent on 
                    // this cycle. Hence, we can fit a term 
                    // symbol into next transaction
                    else
                        d_state = ST_TERM;
                end
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
            // in case W_DATA==16, q_crc_id should
            // be checked
            if (W_DATA == 32 | q_crc_id != '0)
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
    endcase
end

always_ff @(posedge i_clk) begin : reg_ctrl
    if (i_reset) begin
        q_state <= ST_INIT;
        q_tready <= '0;
    end
    else if (i_clk_en) begin
        q_state  <= d_state;
        q_trans_id <= d_trans_id;
        q_hdr_id <= d_hdr_id;
        q_pld_cnt <= d_pld_cnt;
        q_crc_id  <= d_crc_id;
        q_ifg_cnt <= d_ifg_cnt;
        if (term_rcvd)
            q_tready <= 1'b0;
        else if (reset_states)
            q_tready <= 1'b1;

        // q_tready goes low when term 
        // is received. Hence, when needed, 
        // q_last_data will have last received data
        if (q_tready) begin
            q_last_valid <= d_last_valid;
            q_last_data  <= d_last_data;
        end
    end
end

assign s_axis_tready = (i_clk_en & !o_gen_error) ? q_tready : '0;

endmodule : mac_tx_ctrl