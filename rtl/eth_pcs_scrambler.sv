module eth_pcs_scrambler #(
    // 0 - scrambler, 1 - descrambler
    parameter SCR_MODE = 0
) (
    input i_clk,
    input i_reset,
    input i_clk_en,
    input [W_DATA-1:0] i_pld_data,
    output [W_DATA-1:0] o_scr_data
);

logic [W_SCR-1:0] d_scr, q_scr, w_scr;

// LFSR scrambler
function automatic void scramble(
    input logic [15:0] i_data,
    input logic [W_SCR-1:0] i_scr,
    output logic [15:0] o_data,
    output logic [W_SCR-1:0] o_scr
);
    o_scr[0] = i_scr[23] + i_scr[42] + i_data[15];
    o_scr[1] = i_scr[24] + i_scr[43] + i_data[14];
    o_scr[2] = i_scr[25] + i_scr[44] + i_data[13];
    o_scr[3] = i_scr[26] + i_scr[45] + i_data[12];
    o_scr[4] = i_scr[27] + i_scr[46] + i_data[11];
    o_scr[5] = i_scr[28] + i_scr[47] + i_data[10];
    o_scr[6] = i_scr[29] + i_scr[48] + i_data[9];
    o_scr[7] = i_scr[30] + i_scr[49] + i_data[8];
    o_scr[8] = i_scr[31] + i_scr[50] + i_data[7];
    o_scr[9] = i_scr[32] + i_scr[51] + i_data[6];
    o_scr[10] = i_scr[33] + i_scr[52] + i_data[5];
    o_scr[11] = i_scr[34] + i_scr[53] + i_data[4];
    o_scr[12] = i_scr[35] + i_scr[54] + i_data[3];
    o_scr[13] = i_scr[36] + i_scr[55] + i_data[2];
    o_scr[14] = i_scr[37] + i_scr[56] + i_data[1];
    o_scr[15] = i_scr[38] + i_scr[57] + i_data[0];
    o_scr[W_SCR-1:16] = o_scr[W_SCR-17:0];

    for (int i=0; i<15; i++)
        o_data[i] = o_scr[15-i];
endfunction

// LFSR Descrambler
function automatic void descramble(
    input logic [15:0] i_data,
    input logic [W_SCR-1:0] i_scr,
    output logic [15:0] o_data,
    output logic [W_SCR-1:0] o_scr
);
    o_scr = i_scr << 16;
    for (int i=0; i<15; i++)
        o_scr[i] = i_data[15-i];

    o_data[0] = i_scr[38] + i_scr[57] + i_data[0];
    o_data[1] = i_scr[37] + i_scr[56] + i_data[1];
    o_data[2] = i_scr[36] + i_scr[55] + i_data[2];
    o_data[3] = i_scr[35] + i_scr[54] + i_data[3];
    o_data[4] = i_scr[34] + i_scr[53] + i_data[4];
    o_data[5] = i_scr[33] + i_scr[52] + i_data[5];
    o_data[6] = i_scr[32] + i_scr[51] + i_data[6];
    o_data[7] = i_scr[31] + i_scr[50] + i_data[7];
    o_data[8] = i_scr[30] + i_scr[49] + i_data[8];
    o_data[9] = i_scr[29] + i_scr[48] + i_data[9];
    o_data[10] = i_scr[28] + i_scr[47] + i_data[10];
    o_data[11] = i_scr[27] + i_scr[46] + i_data[11];
    o_data[12] = i_scr[26] + i_scr[45] + i_data[12];
    o_data[13] = i_scr[25] + i_scr[44] + i_data[13];
    o_data[14] = i_scr[24] + i_scr[43] + i_data[14];
    o_data[15] = i_scr[23] + i_scr[42] + i_data[15];
endfunction

always_comb begin : main_logic
    d_scr = q_scr;
    for (int i=0; i<W_DATA; i+=16) begin
        if (SCR_MODE == 0)
            scramble(i_pld_data[i+:16], d_scr,
                     o_scr_data[i+:16], w_scr);
        else
            descramble(i_pld_data[i+:16], d_scr,
                       o_scr_data[i+:16], w_scr);
        d_scr = w_scr;
    end
end

always_ff @(posedge i_clk) begin
    if (i_reset) 
        q_scr <= '1;
    else if (i_clk_en)
        q_scr <= d_scr; 
end
    
endmodule : eth_pcs_scrambler