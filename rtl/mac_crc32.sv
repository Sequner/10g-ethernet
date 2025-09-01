import cmn_params::*;

module mac_crc32 (
    input i_clk,
    input i_reset,
    input i_clk_en,
    input i_crc_clr,
    input [N_SYMBOLS-1:0] i_crc_en,
    input  logic [N_SYMBOLS-1:0][W_SYMBOL-1:0] i_data,
    output logic [W_CRC-1:0] o_crc
);

logic [W_CRC-1:0] d_crc, q_crc, crc;

function [W_CRC-1:0] reverse(
    input [W_CRC-1:0] i_crc
);
    for (int i=0; i<W_CRC; i++)
        reverse[i] = i_crc[W_CRC-1-i];
endfunction

always_comb begin
    d_crc = q_crc;
    crc = q_crc;
    unique if (i_crc_clr)
        d_crc = CRC_RESET;
    else begin
        for (int i=0; i<N_SYMBOLS; i++) begin
            if (i_crc_en[i])
                calc_crc_8bit(d_crc, i_data[i], crc);
            d_crc = crc;
        end
    end
end

always_ff @(posedge i_clk) begin : crc_reg
    if (i_reset)
        q_crc <= CRC_RESET;
    else if (i_clk_en) 
        q_crc <= d_crc;
end

assign o_crc = ~reverse(q_crc);

endmodule : mac_crc32