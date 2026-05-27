module receive_synchronizer (
    input  wire        i_txclk,
    input  wire        i_rxclk,

    input  wire [63:0] i_RXD,
    input  wire [7:0]  i_RXC,

    output wire [63:0] o_RXD,
    output wire [7:0]  o_RXC,
    output wire        o_empty
);

    wire [71:0] read_data;

    async_fifo async_fifo_inst(
        .i_wclk(i_rxclk),
        .i_wrst(1'b0),
        .i_wr(1'b1),
        .i_wdata({i_RXC, i_RXD}),
        .o_wfull(),
        .i_rclk(i_txclk),
        .i_rrst(1'b0),
        .i_rd(1'b1),
        .o_rdata(read_data),
        .o_rempty(o_empty)
    );

    assign o_RXD = read_data[63:0];
    assign o_RXC = read_data[71:64];
endmodule