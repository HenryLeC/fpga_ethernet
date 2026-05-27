`default_nettype none
module pcs_rx #(
    parameter LFSR_INITIAL_STATE = 58'hFEEDFEEDFEEDFEE
) (
    input wire clk,
    
    // XGMII interface
    output wire [63:0] RXD,
    output wire [7:0] RXC,

    input wire [63:0] rx_data,
    input wire [1:0] rx_header
);

    wire [63:0] unscrambled_data;

    reg [57:0] lfsr_state = LFSR_INITIAL_STATE;

    decoder decoder_inst(
        .clk(clk),

        .RXD(RXD),
        .RXC(RXC),

        .rx_header(rx_header),
        .rx_data(unscrambled_data)
    );

    wire [57:0] next_lfsr_state;

    descrambler descrambler_inst(
        .data_in(rx_data),
        .lfsr_state_in(lfsr_state),
        .data_out(unscrambled_data),
        .lfsr_state_out(next_lfsr_state)
    );

    always_ff @(posedge clk) begin: store_lfsr_state
        lfsr_state <= next_lfsr_state;
    end
endmodule