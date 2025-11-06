module packet_sender (
    input i_reset,
    input logic m_axis_clk,
    input logic m_axis_tready,
    output logic m_axis_tvalid,
    output logic [3:0] m_axis_tkeep,
    output logic [31:0] m_axis_tdata,
    output logic m_axis_tlast,
    input [9:0] i_vio_packet_bytes,
    input i_sync_rx_last_received,
    output o_first_byte_sent
);

logic [9:0]  q_packet_bytes;
logic [10:0] q_bytes_sent;
// in case rx hasn't received frames (happens during reset)
logic [4:0]  q_reset_counter;

always_comb begin
    m_axis_tvalid = (q_bytes_sent < q_packet_bytes);
    m_axis_tkeep  = '1;
    if (m_axis_tlast) begin
        case (q_packet_bytes[1:0])
            2'h1: m_axis_tkeep = 4'b0001;
            2'h2: m_axis_tkeep = 4'b0011;
            2'h3: m_axis_tkeep = 4'b0111;
            default: m_axis_tkeep = 4'b1111;
        endcase
    end
    m_axis_tdata  = 32'hFFFFAAAA;
    m_axis_tlast  = (q_bytes_sent + 3'h4 >= q_packet_bytes);
end

always_ff @(posedge m_axis_clk) begin
    // send new packet once last packet was fully received
    // or after timeout
    if (q_bytes_sent >= q_packet_bytes) begin
        if (i_sync_rx_last_received | q_reset_counter == '1)
            q_bytes_sent <= '0;
    end
    else if (m_axis_tvalid & m_axis_tready) begin
        q_bytes_sent <= q_bytes_sent + 3'h4;
    end

    if (q_bytes_sent >= q_packet_bytes)
        q_reset_counter <= q_reset_counter + 1'b1;
    else
        q_reset_counter <= '0;
    
    // only update q_packet_bytes in the beginning of the frame
    if (q_bytes_sent == '0)
        q_packet_bytes <= i_vio_packet_bytes;
end

assign o_first_byte_sent = (q_bytes_sent == '0) & m_axis_tvalid & m_axis_tready;

endmodule