`include "include/code_defs.svh"
module encoder #() (
    input clk,

    // XGMII interface to PCS
    input [63:0] TXD,
    input [7:0] TXC,

    output reg [1:0] header,
    output reg [63:0] data
);
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
            if (ictl == 8'h11 && {idata[39:32], idata[7:0]} == {RS_START, RS_SEQ}) begin // O0 and S4
                return {idata[63:40], 8'h0, idata[31:8], BT_O0S4};
            end else
            if (ictl == 8'h11 && {idata[39:32], idata[7:0]} == {RS_SEQ, RS_SEQ}) begin // O0 and O4
                return {idata[63:40], 8'h0, idata[31:8], BT_O0O4};
            end else
            if (ictl == 8'h01 && idata[7:0] == {RS_START}) begin // S0
                return {idata[63:8], BT_S0};
            end else
            if (ictl == 8'hF1) begin // O0
                return {{4{CC_IDLE}}, 4'h0, idata[31:8], BT_O0};
            end else
            if (ictl == 8'hFF) begin // T0
                return {{7{CC_IDLE}}, 7'h00, BT_T0};
            end else
            if (ictl == 8'hFE) begin // T1
                return {{6{CC_IDLE}}, 6'h00, idata[7:0], BT_T1};
            end else
            if (ictl == 8'hFC) begin // T2
                return {{5{CC_IDLE}}, 5'h00, idata[15:0], BT_T2};
            end else
            if (ictl == 8'hF8) begin // T3
                return {{4{CC_IDLE}}, 4'h00, idata[23:0], BT_T3};
            end else
            if (ictl == 8'hF0) begin // T4
                return {{3{CC_IDLE}}, 3'h00, idata[31:0], BT_T4};
            end else
            if (ictl == 8'hE0) begin // T5
                return {{2{CC_IDLE}}, 2'h00, idata[39:0], BT_T5};
            end else
            if (ictl == 8'hC0) begin // T6
                return {CC_IDLE, 1'h00, idata[47:0], BT_T6};
            end else
            if (ictl == 8'h80) begin // T7
                return {idata[55:0], BT_T7};
            end else begin
                return {{8{CC_ERROR}}, BT_IDLE};
            end
        end
    endfunction

    always_ff @(posedge clk) begin : shift_and_valid_assert
        data <= encode_packet(TXD, TXC);
        header <= TXC == '0 ? 2'b10 : 2'b01;
    end
endmodule