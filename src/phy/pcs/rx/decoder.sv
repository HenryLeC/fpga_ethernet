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
            BT_S0:
                begin
                    xgmii_rx_data = {rx_data[63:8], RS_START};
                    xgmii_rx_control = 8'h01;
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