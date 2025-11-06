module latency_counter (
    input i_tx_clk,
    input i_first_byte_sent,
    input i_sync_byte_received,
    output [5:0] o_first_byte_latency
);

logic q_cnt_stop;
logic [5:0] q_latency_cnt;

always_ff @(posedge i_tx_clk) begin
    if (i_first_byte_sent) begin
        q_cnt_stop <= '0;
        q_latency_cnt <= 1'b1;
    end
    else begin
        if (i_sync_byte_received)
            q_cnt_stop <= '1;
        if (!q_cnt_stop & !i_sync_byte_received)
            q_latency_cnt <= q_latency_cnt + 1'b1;
    end
end

assign o_first_byte_latency = q_latency_cnt;

endmodule