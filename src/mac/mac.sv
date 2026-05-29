module mac (
    input  wire        i_txclk,
    input  wire        i_arst,
    output wire [31:0] o_TXD,
    output wire [3:0]  o_TXC,

    input  wire        i_rxclk,
    input  wire [31:0] i_RXD,
    input  wire [3:0]  i_RXC
);

    wire [31:0] RXD_sync;
    wire [3:0]  RXC_sync;
    wire o_empty;
    receive_synchronizer synch_inst (
        .i_txclk(i_txclk),
        .i_rxclk(i_rxclk),

        .i_RXD(i_RXD),
        .i_RXC(i_RXC),

        .o_RXD(RXD_sync),
        .o_RXC(RXC_sync),
        .o_empty(o_empty)
    );


    sfp_ila sfp_ila (
        .clk(i_txclk),
        .probe0(o_TXC),
        .probe1(o_TXD),
        .probe2(RXC_sync),
        .probe3(RXD_sync),
        .probe4(o_empty)
    );


    dummy_frame_encoder frame_gen_inst (
        .i_clk(i_txclk),
        .i_arst(i_arst),

        .TXC(o_TXC),
        .TXD(o_TXD)
    );

endmodule