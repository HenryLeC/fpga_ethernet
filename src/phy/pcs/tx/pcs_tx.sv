`default_nettype none
module pcs_tx #(
    parameter bit [57:0] LFSR_INITIAL_STATE = 58'hFEEDFEEDFEEDFEE
) (
    input  wire        clk,
    input  wire        arst,
    // XGMII interface
    input  wire [31:0] TXD,
    input  wire [3:0]  TXC,

    output wire [31:0] tx_data,
    output wire [1:0]  tx_header,
    output wire        header_valid
);

    reg [31:0]  prev_TXD;
    reg [3:0]   prev_TXC;

    wire [63:0] full_TXD = {TXD, prev_TXD};
    wire [7:0]  full_TXC = {TXC, prev_TXC};
    reg         full_valid;

    initial {prev_TXC, prev_TXD} = 0;
    initial full_valid = 0;
    always_ff @(posedge clk or posedge arst) begin
        if (arst)
            {prev_TXC, prev_TXD, full_valid} <= 0;
        else
            {prev_TXC, prev_TXD, full_valid} <= {TXC, TXD, ~full_valid};
    end

    wire [63:0] unscrambled_data;
    reg         encoded_valid;

    encoder encoder_inst(
        .clk(clk),

        .TXD(full_TXD),
        .TXC(full_TXC),

        .header(tx_header),
        .data(unscrambled_data)
    );

    assign header_valid = encoded_valid;

    always_ff @(posedge clk)
        encoded_valid <= full_valid;

    reg  [57:0] lfsr_state = LFSR_INITIAL_STATE;
    wire [57:0] next_lfsr_state;

    reg  [31:0] upper_data;
    wire [63:0] scrambled_data;

    scrambler scrambler_inst(
        .data_in(unscrambled_data),
        .lfsr_state_in(lfsr_state),
        .data_out(scrambled_data),
        .lfsr_state_out(next_lfsr_state)
    );

    always_ff @(posedge clk) begin: store_lfsr_state
        if(encoded_valid) begin
            lfsr_state <= next_lfsr_state;
            upper_data <= scrambled_data[63:32];
        end
    end

    assign tx_data = header_valid ? scrambled_data[31:0] : upper_data;
endmodule