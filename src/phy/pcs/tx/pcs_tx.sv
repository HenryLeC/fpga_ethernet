`default_nettype none
module pcs_tx #(
    parameter LFSR_INITIAL_STATE = 58'hFEEDFEEDFEEDFEE
) (
    input wire clk,
    
    // XGMII interface
    input wire [63:0] TXD,
    input wire [7:0] TXC,

    output wire [63:0] tx_data,
    output wire [1:0] tx_header
);

    wire [63:0] unscrambled_data;

    reg [57:0] lfsr_state = LFSR_INITIAL_STATE;

    encoder encoder_inst(
        .clk(clk),

        .TXD(TXD),
        .TXC(TXC),

        .header(tx_header),
        .data(unscrambled_data)
    );

    wire [57:0] next_lfsr_state;

    scrambler scrambler_inst(
        .data_in(unscrambled_data),
        .lfsr_state_in(lfsr_state),
        .data_out(tx_data),
        .lfsr_state_out(next_lfsr_state)
    );

    always_ff @(posedge clk) begin: store_lfsr_state
        lfsr_state <= next_lfsr_state;
    end
endmodule