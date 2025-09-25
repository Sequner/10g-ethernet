module eth_pcs_scrambler #(
    // 0 - scrambler, 1 - descrambler
    parameter SCR_MODE = 0
) (
    input i_clk,
    input i_reset,
    input i_clk_en,
    input [W_DATA-1:0] i_pld_data,
    output logic [W_DATA-1:0] o_scr_data
);

logic [W_SCR-1:0] d_scr, q_scr, w_scr;

// Scrambler - 32 bits
function automatic void scramble_32b(
    input logic [31:0] i_data,
    input logic [W_SCR-1:0] i_scr,
    output logic [W_SCR-1:0] o_scr
);
    o_scr[0]  = i_scr[7]  ^ i_scr[26] ^ i_data[31];
    o_scr[1]  = i_scr[8]  ^ i_scr[27] ^ i_data[30];
    o_scr[2]  = i_scr[9]  ^ i_scr[28] ^ i_data[29];
    o_scr[3]  = i_scr[10] ^ i_scr[29] ^ i_data[28];
    o_scr[4]  = i_scr[11] ^ i_scr[30] ^ i_data[27];
    o_scr[5]  = i_scr[12] ^ i_scr[31] ^ i_data[26];
    o_scr[6]  = i_scr[13] ^ i_scr[32] ^ i_data[25];
    o_scr[7]  = i_scr[14] ^ i_scr[33] ^ i_data[24];
    o_scr[8]  = i_scr[15] ^ i_scr[34] ^ i_data[23];
    o_scr[9]  = i_scr[16] ^ i_scr[35] ^ i_data[22];
    o_scr[10] = i_scr[17] ^ i_scr[36] ^ i_data[21];
    o_scr[11] = i_scr[18] ^ i_scr[37] ^ i_data[20];
    o_scr[12] = i_scr[19] ^ i_scr[38] ^ i_data[19];
    o_scr[13] = i_scr[20] ^ i_scr[39] ^ i_data[18];
    o_scr[14] = i_scr[21] ^ i_scr[40] ^ i_data[17];
    o_scr[15] = i_scr[22] ^ i_scr[41] ^ i_data[16];   
    o_scr[16] = i_scr[23] ^ i_scr[42] ^ i_data[15];
    o_scr[17] = i_scr[24] ^ i_scr[43] ^ i_data[14];
    o_scr[18] = i_scr[25] ^ i_scr[44] ^ i_data[13];
    o_scr[19] = i_scr[26] ^ i_scr[45] ^ i_data[12];
    o_scr[20] = i_scr[27] ^ i_scr[46] ^ i_data[11];
    o_scr[21] = i_scr[28] ^ i_scr[47] ^ i_data[10];
    o_scr[22] = i_scr[29] ^ i_scr[48] ^ i_data[9];
    o_scr[23] = i_scr[30] ^ i_scr[49] ^ i_data[8];
    o_scr[24] = i_scr[31] ^ i_scr[50] ^ i_data[7];
    o_scr[25] = i_scr[32] ^ i_scr[51] ^ i_data[6];
    o_scr[26] = i_scr[33] ^ i_scr[52] ^ i_data[5];
    o_scr[27] = i_scr[34] ^ i_scr[53] ^ i_data[4];
    o_scr[28] = i_scr[35] ^ i_scr[54] ^ i_data[3];
    o_scr[29] = i_scr[36] ^ i_scr[55] ^ i_data[2];
    o_scr[30] = i_scr[37] ^ i_scr[56] ^ i_data[1];
    o_scr[31] = i_scr[38] ^ i_scr[57] ^ i_data[0];
    o_scr[W_SCR-1:32] = i_scr[(W_SCR-1)-32:0];
endfunction

always_comb begin : main_logic
    d_scr = q_scr;
    // TODO: add scrambler function for 16 bits
    scramble_32b(i_pld_data, q_scr, w_scr);
    o_scr_data = reverse(w_scr[W_DATA-1:0]);
    if (SCR_MODE == 0) // scrambler
        d_scr = w_scr;
    else // descrambler
        d_scr = {q_scr[W_DATA-1:0], reverse(i_pld_data)};
end

always_ff @(posedge i_clk) begin
    if (i_clk_en)
        q_scr <= d_scr; 
end
    
endmodule : eth_pcs_scrambler