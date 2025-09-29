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

logic [W_CRC-1:0] d_crc, q_crc;

function [W_CRC-1:0] reverse(
    input [W_CRC-1:0] i_crc
);
    for (int i=0; i<W_CRC; i++)
        reverse[i] = i_crc[W_CRC-1-i];
endfunction

always_comb begin
    unique if (i_crc_clr)
        d_crc = CRC_RESET;
    else begin // TODO: if W_DATA==16 is implemented, add parameterization
        case (i_crc_en)
            4'b0000: d_crc = q_crc;
            4'b0001: calc_crc_8bit (q_crc, i_data[0:0], d_crc);
            4'b0011: calc_crc_16bit(q_crc, i_data[1:0], d_crc);
            4'b0111: calc_crc_24bit(q_crc, i_data[2:0], d_crc);
            4'b1111: calc_crc_32bit(q_crc, i_data[3:0], d_crc);
            default: begin
                d_crc = q_crc;
                assert(0) else $fatal("ERROR: DATA VALID IS NOT CONTINUOS");
            end
        endcase
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