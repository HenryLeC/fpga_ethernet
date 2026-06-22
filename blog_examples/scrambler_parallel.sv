module scrambler_parallel (
    input wire [63:0] data_in,
    input wire [57:0] state_in,

    output wire [63:0] data_out,
    output wire [57:0] state_out
);

    wire [121:0] scrambler_out;
    scrambler_gen scrambler_inst (
        .data_in({state_in, { << {data_in}}}),
        .data_out(scrambler_out)
    );

    assign data_out = { << {scrambler_out[63:0]}};
    assign state_out = scrambler_out[121:64];
endmodule

module scrambler_gen(
    input wire [121:0] data_in,
    output wire [121:0] data_out
);
assign data_out[0] = data_in[0] ^ data_in[39] ^ data_in[58] ^ data_in[78] ^ data_in[116];
assign data_out[1] = data_in[1] ^ data_in[40] ^ data_in[59] ^ data_in[79] ^ data_in[117];
assign data_out[2] = data_in[2] ^ data_in[41] ^ data_in[60] ^ data_in[80] ^ data_in[118];
assign data_out[3] = data_in[3] ^ data_in[42] ^ data_in[61] ^ data_in[81] ^ data_in[119];
assign data_out[4] = data_in[4] ^ data_in[43] ^ data_in[62] ^ data_in[82] ^ data_in[120];
assign data_out[5] = data_in[5] ^ data_in[44] ^ data_in[63] ^ data_in[83] ^ data_in[121];
assign data_out[6] = data_in[6] ^ data_in[45] ^ data_in[64] ^ data_in[84] ^ data_in[103];
assign data_out[7] = data_in[7] ^ data_in[46] ^ data_in[65] ^ data_in[85] ^ data_in[104];
assign data_out[8] = data_in[8] ^ data_in[47] ^ data_in[66] ^ data_in[86] ^ data_in[105];
assign data_out[9] = data_in[9] ^ data_in[48] ^ data_in[67] ^ data_in[87] ^ data_in[106];
assign data_out[10] = data_in[10] ^ data_in[49] ^ data_in[68] ^ data_in[88] ^ data_in[107];
assign data_out[11] = data_in[11] ^ data_in[50] ^ data_in[69] ^ data_in[89] ^ data_in[108];
assign data_out[12] = data_in[12] ^ data_in[51] ^ data_in[70] ^ data_in[90] ^ data_in[109];
assign data_out[13] = data_in[13] ^ data_in[52] ^ data_in[71] ^ data_in[91] ^ data_in[110];
assign data_out[14] = data_in[14] ^ data_in[53] ^ data_in[72] ^ data_in[92] ^ data_in[111];
assign data_out[15] = data_in[15] ^ data_in[54] ^ data_in[73] ^ data_in[93] ^ data_in[112];
assign data_out[16] = data_in[16] ^ data_in[55] ^ data_in[74] ^ data_in[94] ^ data_in[113];
assign data_out[17] = data_in[17] ^ data_in[56] ^ data_in[75] ^ data_in[95] ^ data_in[114];
assign data_out[18] = data_in[18] ^ data_in[57] ^ data_in[76] ^ data_in[96] ^ data_in[115];
assign data_out[19] = data_in[19] ^ data_in[58] ^ data_in[77] ^ data_in[97] ^ data_in[116];
assign data_out[20] = data_in[20] ^ data_in[59] ^ data_in[78] ^ data_in[98] ^ data_in[117];
assign data_out[21] = data_in[21] ^ data_in[60] ^ data_in[79] ^ data_in[99] ^ data_in[118];
assign data_out[22] = data_in[22] ^ data_in[61] ^ data_in[80] ^ data_in[100] ^ data_in[119];
assign data_out[23] = data_in[23] ^ data_in[62] ^ data_in[81] ^ data_in[101] ^ data_in[120];
assign data_out[24] = data_in[24] ^ data_in[63] ^ data_in[82] ^ data_in[102] ^ data_in[121];
assign data_out[25] = data_in[25] ^ data_in[64] ^ data_in[83];
assign data_out[26] = data_in[26] ^ data_in[65] ^ data_in[84];
assign data_out[27] = data_in[27] ^ data_in[66] ^ data_in[85];
assign data_out[28] = data_in[28] ^ data_in[67] ^ data_in[86];
assign data_out[29] = data_in[29] ^ data_in[68] ^ data_in[87];
assign data_out[30] = data_in[30] ^ data_in[69] ^ data_in[88];
assign data_out[31] = data_in[31] ^ data_in[70] ^ data_in[89];
assign data_out[32] = data_in[32] ^ data_in[71] ^ data_in[90];
assign data_out[33] = data_in[33] ^ data_in[72] ^ data_in[91];
assign data_out[34] = data_in[34] ^ data_in[73] ^ data_in[92];
assign data_out[35] = data_in[35] ^ data_in[74] ^ data_in[93];
assign data_out[36] = data_in[36] ^ data_in[75] ^ data_in[94];
assign data_out[37] = data_in[37] ^ data_in[76] ^ data_in[95];
assign data_out[38] = data_in[38] ^ data_in[77] ^ data_in[96];
assign data_out[39] = data_in[39] ^ data_in[78] ^ data_in[97];
assign data_out[40] = data_in[40] ^ data_in[79] ^ data_in[98];
assign data_out[41] = data_in[41] ^ data_in[80] ^ data_in[99];
assign data_out[42] = data_in[42] ^ data_in[81] ^ data_in[100];
assign data_out[43] = data_in[43] ^ data_in[82] ^ data_in[101];
assign data_out[44] = data_in[44] ^ data_in[83] ^ data_in[102];
assign data_out[45] = data_in[45] ^ data_in[84] ^ data_in[103];
assign data_out[46] = data_in[46] ^ data_in[85] ^ data_in[104];
assign data_out[47] = data_in[47] ^ data_in[86] ^ data_in[105];
assign data_out[48] = data_in[48] ^ data_in[87] ^ data_in[106];
assign data_out[49] = data_in[49] ^ data_in[88] ^ data_in[107];
assign data_out[50] = data_in[50] ^ data_in[89] ^ data_in[108];
assign data_out[51] = data_in[51] ^ data_in[90] ^ data_in[109];
assign data_out[52] = data_in[52] ^ data_in[91] ^ data_in[110];
assign data_out[53] = data_in[53] ^ data_in[92] ^ data_in[111];
assign data_out[54] = data_in[54] ^ data_in[93] ^ data_in[112];
assign data_out[55] = data_in[55] ^ data_in[94] ^ data_in[113];
assign data_out[56] = data_in[56] ^ data_in[95] ^ data_in[114];
assign data_out[57] = data_in[57] ^ data_in[96] ^ data_in[115];
assign data_out[58] = data_in[58] ^ data_in[97] ^ data_in[116];
assign data_out[59] = data_in[59] ^ data_in[98] ^ data_in[117];
assign data_out[60] = data_in[60] ^ data_in[99] ^ data_in[118];
assign data_out[61] = data_in[61] ^ data_in[100] ^ data_in[119];
assign data_out[62] = data_in[62] ^ data_in[101] ^ data_in[120];
assign data_out[63] = data_in[63] ^ data_in[102] ^ data_in[121];

assign data_out[64] = data_in[0] ^ data_in[39] ^ data_in[58] ^ data_in[78] ^ data_in[116];
assign data_out[65] = data_in[1] ^ data_in[40] ^ data_in[59] ^ data_in[79] ^ data_in[117];
assign data_out[66] = data_in[2] ^ data_in[41] ^ data_in[60] ^ data_in[80] ^ data_in[118];
assign data_out[67] = data_in[3] ^ data_in[42] ^ data_in[61] ^ data_in[81] ^ data_in[119];
assign data_out[68] = data_in[4] ^ data_in[43] ^ data_in[62] ^ data_in[82] ^ data_in[120];
assign data_out[69] = data_in[5] ^ data_in[44] ^ data_in[63] ^ data_in[83] ^ data_in[121];
assign data_out[70] = data_in[6] ^ data_in[45] ^ data_in[64] ^ data_in[84] ^ data_in[103];
assign data_out[71] = data_in[7] ^ data_in[46] ^ data_in[65] ^ data_in[85] ^ data_in[104];
assign data_out[72] = data_in[8] ^ data_in[47] ^ data_in[66] ^ data_in[86] ^ data_in[105];
assign data_out[73] = data_in[9] ^ data_in[48] ^ data_in[67] ^ data_in[87] ^ data_in[106];
assign data_out[74] = data_in[10] ^ data_in[49] ^ data_in[68] ^ data_in[88] ^ data_in[107];
assign data_out[75] = data_in[11] ^ data_in[50] ^ data_in[69] ^ data_in[89] ^ data_in[108];
assign data_out[76] = data_in[12] ^ data_in[51] ^ data_in[70] ^ data_in[90] ^ data_in[109];
assign data_out[77] = data_in[13] ^ data_in[52] ^ data_in[71] ^ data_in[91] ^ data_in[110];
assign data_out[78] = data_in[14] ^ data_in[53] ^ data_in[72] ^ data_in[92] ^ data_in[111];
assign data_out[79] = data_in[15] ^ data_in[54] ^ data_in[73] ^ data_in[93] ^ data_in[112];
assign data_out[80] = data_in[16] ^ data_in[55] ^ data_in[74] ^ data_in[94] ^ data_in[113];
assign data_out[81] = data_in[17] ^ data_in[56] ^ data_in[75] ^ data_in[95] ^ data_in[114];
assign data_out[82] = data_in[18] ^ data_in[57] ^ data_in[76] ^ data_in[96] ^ data_in[115];
assign data_out[83] = data_in[19] ^ data_in[58] ^ data_in[77] ^ data_in[97] ^ data_in[116];
assign data_out[84] = data_in[20] ^ data_in[59] ^ data_in[78] ^ data_in[98] ^ data_in[117];
assign data_out[85] = data_in[21] ^ data_in[60] ^ data_in[79] ^ data_in[99] ^ data_in[118];
assign data_out[86] = data_in[22] ^ data_in[61] ^ data_in[80] ^ data_in[100] ^ data_in[119];
assign data_out[87] = data_in[23] ^ data_in[62] ^ data_in[81] ^ data_in[101] ^ data_in[120];
assign data_out[88] = data_in[24] ^ data_in[63] ^ data_in[82] ^ data_in[102] ^ data_in[121];
assign data_out[89] = data_in[25] ^ data_in[64] ^ data_in[83];
assign data_out[90] = data_in[26] ^ data_in[65] ^ data_in[84];
assign data_out[91] = data_in[27] ^ data_in[66] ^ data_in[85];
assign data_out[92] = data_in[28] ^ data_in[67] ^ data_in[86];
assign data_out[93] = data_in[29] ^ data_in[68] ^ data_in[87];
assign data_out[94] = data_in[30] ^ data_in[69] ^ data_in[88];
assign data_out[95] = data_in[31] ^ data_in[70] ^ data_in[89];
assign data_out[96] = data_in[32] ^ data_in[71] ^ data_in[90];
assign data_out[97] = data_in[33] ^ data_in[72] ^ data_in[91];
assign data_out[98] = data_in[34] ^ data_in[73] ^ data_in[92];
assign data_out[99] = data_in[35] ^ data_in[74] ^ data_in[93];
assign data_out[100] = data_in[36] ^ data_in[75] ^ data_in[94];
assign data_out[101] = data_in[37] ^ data_in[76] ^ data_in[95];
assign data_out[102] = data_in[38] ^ data_in[77] ^ data_in[96];
assign data_out[103] = data_in[39] ^ data_in[78] ^ data_in[97];
assign data_out[104] = data_in[40] ^ data_in[79] ^ data_in[98];
assign data_out[105] = data_in[41] ^ data_in[80] ^ data_in[99];
assign data_out[106] = data_in[42] ^ data_in[81] ^ data_in[100];
assign data_out[107] = data_in[43] ^ data_in[82] ^ data_in[101];
assign data_out[108] = data_in[44] ^ data_in[83] ^ data_in[102];
assign data_out[109] = data_in[45] ^ data_in[84] ^ data_in[103];
assign data_out[110] = data_in[46] ^ data_in[85] ^ data_in[104];
assign data_out[111] = data_in[47] ^ data_in[86] ^ data_in[105];
assign data_out[112] = data_in[48] ^ data_in[87] ^ data_in[106];
assign data_out[113] = data_in[49] ^ data_in[88] ^ data_in[107];
assign data_out[114] = data_in[50] ^ data_in[89] ^ data_in[108];
assign data_out[115] = data_in[51] ^ data_in[90] ^ data_in[109];
assign data_out[116] = data_in[52] ^ data_in[91] ^ data_in[110];
assign data_out[117] = data_in[53] ^ data_in[92] ^ data_in[111];
assign data_out[118] = data_in[54] ^ data_in[93] ^ data_in[112];
assign data_out[119] = data_in[55] ^ data_in[94] ^ data_in[113];
assign data_out[120] = data_in[56] ^ data_in[95] ^ data_in[114];
assign data_out[121] = data_in[57] ^ data_in[96] ^ data_in[115];
endmodule