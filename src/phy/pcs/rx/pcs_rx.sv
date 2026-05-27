`default_nettype none
module pcs_rx #(
    parameter bit [57:0] LFSR_INITIAL_STATE = 58'hFEEDFEEDFEEDFEE
) (
    input wire clk,
    
    // XGMII interface
    output reg [31:0] RXD,
    output reg [3:0] RXC,

    input wire [31:0] rx_data,
    input wire [1:0]  rx_header,
    input wire        header_valid
);

    reg [1:0] header;
    reg [31:0] prev_block;

    wire [63:0] full_block = {rx_data, prev_block};
    reg         full_valid;


    initial full_valid = 0;
    always_ff @(posedge clk) begin
        prev_block <= rx_data;

        if (header_valid) begin
            header <= rx_header;
        end
        full_valid <= header_valid;
    end

    wire [63:0] unscrambled_data;

    reg  [57:0] lfsr_state = LFSR_INITIAL_STATE;
    wire [57:0] next_lfsr_state;

    descrambler descrambler_inst(
        .data_in(full_block),
        .lfsr_state_in(lfsr_state),
        .data_out(unscrambled_data),
        .lfsr_state_out(next_lfsr_state)
    );

    always_ff @(posedge clk) begin: store_lfsr_state
        if (full_valid)
            lfsr_state <= next_lfsr_state;
    end

    wire [63:0] RXD_full;
    wire [7:0]  RXC_full;
    reg         RXX_valid;

    reg [31:0] RXD_upper;
    reg [3:0]  RXC_upper;

    decoder decoder_inst(
        .clk(clk),

        .RXD(RXD_full),
        .RXC(RXC_full),

        .rx_header(rx_header),
        .rx_data(unscrambled_data)
    );

    always_ff @(posedge clk) begin
        RXX_valid <= full_valid;
        if (RXX_valid) begin
            RXD_upper <= RXD_full[63:32];
            RXC_upper <= RXC_full[7:4];
        end
    end

    always_comb begin: XGMII_switch_word
        if (RXX_valid) begin
            RXD = RXD_full[31:0];
            RXC = RXC_full[3:0];
        end else begin
            RXD = RXD_upper;
            RXC = RXC_upper;
        end
    end

endmodule