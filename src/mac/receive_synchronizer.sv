module receive_synchronizer (
    input  wire        i_txclk,
    input  wire        i_rxclk,

    input  wire [31:0] i_RXD,
    input  wire [3:0]  i_RXC,

    output logic [31:0] o_RXD,
    output logic [3:0]  o_RXC,
    output logic        o_empty
);

    wire [35:0] read_data;
    wire        read_empty;

    async_fifo #(
        .DATA_WIDTH(36)
    ) async_fifo_inst  (
        .i_wclk(i_rxclk),
        .i_wrst(1'b0),
        .i_wr(1'b1),
        .i_wdata({i_RXC, i_RXD}),
        .o_wfull(),
        .i_rclk(i_txclk),
        .i_rrst(1'b0),
        .i_rd(1'b1),
        .o_rdata(read_data),
        .o_rempty(read_empty)
    );

    always_ff @(posedge i_txclk) begin
        o_RXD <= read_data[31:0];
        o_RXC <= read_data[35:32];
        o_empty <= read_empty;
    end

endmodule