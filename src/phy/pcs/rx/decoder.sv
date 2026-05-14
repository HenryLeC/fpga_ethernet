`include "include/code_defs.svh"
module decoder #() (
    input clk,
    input arst_n,

    input [63:0] rx_data,
    input [1:0] rx_header,

    // XGMII interface to MAC
    output reg [63:0] RXD,
    output reg [7:0] RXC
);

    import code_defs::*;

    reg [63:0] xgmii_rx_data;
    reg [7:0] xgmii_rx_control;

    always_comb begin : main_decode
        if (rx_header == 2'b10) begin
            xgmii_rx_data = rx_data;
            xgmii_rx_control = 8'h00;
        end
        else begin
            case (rx_data[7:0])
            BT_IDLE:
                begin
                    xgmii_rx_data = {8{RS_IDLE}};
                    xgmii_rx_control = 8'hFF;
                end
            BT_O4:
                begin
                    xgmii_rx_data = {rx_data[63:40], RS_SEQ, {4{RS_IDLE}}};
                    xgmii_rx_control = 8'h1F;
                end
            BT_S4:
                begin
                    xgmii_rx_data = {rx_data[63:40], RS_START, {4{RS_IDLE}}};
                    xgmii_rx_control = 8'h1F;
                end
            BT_O0S4:
                begin
                    xgmii_rx_data = {rx_data[63:40], RS_START, rx_data[31:8], RS_SEQ};
                    xgmii_rx_control = 8'h11;
                end
            BT_O0O4:
                begin
                    xgmii_rx_data = {rx_data[63:40], RS_SEQ, rx_data[31:8], RS_SEQ};
                    xgmii_rx_control = 8'h11;
                end
            BT_S0:
                begin
                    xgmii_rx_data = {rx_data[63:8], RS_START};
                    xgmii_rx_control = 8'h01;
                end
            BT_O0:
                begin
                    xgmii_rx_data = {{4{RS_IDLE}}, rx_data[31:8], RS_SEQ};
                    xgmii_rx_control = 8'hF1;
                end
            BT_T0:
                begin
                    xgmii_rx_data = {{7{RS_IDLE}}, RS_TERM};
                    xgmii_rx_control = 8'hFF;
                end
            BT_T1:
                begin
                    xgmii_rx_data = {{6{RS_IDLE}}, RS_TERM, rx_data[7:0]};
                    xgmii_rx_control = 8'hFE;
                end
            BT_T2:
                begin
                    xgmii_rx_data = {{5{RS_IDLE}}, RS_TERM, rx_data[15:0]};
                    xgmii_rx_control = 8'hFC;
                end
            BT_T3:
                begin
                    xgmii_rx_data = {{4{RS_IDLE}}, RS_TERM, rx_data[23:0]};
                    xgmii_rx_control = 8'hF8;
                end
            BT_T4:
                begin
                    xgmii_rx_data = {{3{RS_IDLE}}, RS_TERM, rx_data[31:0]};
                    xgmii_rx_control = 8'hF0;
                end
            BT_T5:
                begin
                    xgmii_rx_data = {{2{RS_IDLE}}, RS_TERM, rx_data[39:0]};
                    xgmii_rx_control = 8'hE0;
                end
            BT_T6:
                begin
                    xgmii_rx_data = {RS_IDLE, RS_TERM, rx_data[47:0]};
                    xgmii_rx_control = 8'hC0;
                end
            BT_T7:
                begin
                    xgmii_rx_data = {RS_TERM, rx_data[55:0]};
                    xgmii_rx_control = 8'h80;
                end
            default:
                begin
                    xgmii_rx_data = 64'h0;
                    xgmii_rx_control = 8'h00;
                end
            endcase
        end
    end

    always_ff @(posedge clk or negedge arst_n) begin
        if (!arst_n) begin
            RXD <= '0;
            RXC <= '0;
        end else begin
            RXD <= xgmii_rx_data;
            RXC <= xgmii_rx_control;
        end
    end

endmodule