`include "include/code_defs.svh"
module encoder #() (
    input clk,
    input arst_n,

    // XGMII interface to PCS
    input [31:0] TXD,
    input [3:0] TXC,

    // Unscrambled block (one valid every 2 cycles)
    output reg block_valid,
    output reg [1:0] header,
    output reg [63:0] data
);

    reg [31:0] prev_txd;
    reg [3:0] prev_txc;

    wire [63:0] concat_txd = {TXD, prev_txd};
    wire [7:0] concat_txc = {TXC, prev_txc};

    import code_defs::*;

    function automatic logic [63:0] encode_packet(input logic [63:0] idata, input logic [7:0] ictl);
        if (ictl == '0) begin // If we have no control blocks we don't need to modify blocks
            return idata;
        end else begin
            if (ictl == 8'hFF && idata == {8{RS_IDLE}}) begin // All blocks are idle
                return {{8{CC_IDLE}}, BT_IDLE};
            end else
            if (ictl == 8'h1F && idata[39:0] == {RS_SEQ, {4{RS_IDLE}}}) begin // Seq control code in O4
                return {idata[63:40], 4'h0, {4{CC_IDLE}}, BT_O4};
            end else
            if (ictl == 8'h1F && idata[39:0] == {RS_START, {4{RS_IDLE}}}) begin // Start control code in S4
                return {idata[63:40], 4'h0, {4{CC_IDLE}}, BT_S4};
            end else
            if (ictl == 8'h01 && idata[7:0] == {RS_START}) begin
                return {idata[63:8], BT_S0};
            end
            // TODO! Missing options
        end
    endfunction

    always_ff @( posedge clk or negedge arst_n ) begin : shift_and_valid_assert
        if (!arst_n) begin
            block_valid <= 1;
        end
        else begin
            prev_txd <= TXD;
            prev_txc <= TXC;
            block_valid <= ~block_valid; // The output is valid every other cycle
            data <= encode_packet(concat_txd, concat_txc);
            header <= concat_txc == '0 ? 2'b10 : 2'b01;
        end
    end
endmodule