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

    wire valid, last, ready;
    wire [31:0] data;


    frame_encoder frame_encoder_inst (
        .i_clk(i_txclk),
        .i_arst(i_arst),

        .i_clientdata(data),
        .i_clientdata_valid({4{valid}}),
        .i_last(last),
        .o_ready(ready),

        .TXC(o_TXC),
        .TXD(o_TXD)
    );

    wire [31:0] udp_data_tdata;
    wire [15:0] udp_data_tlength;
    wire udp_data_tready, udp_data_tvalid, udp_data_tlast;

    ipv4_udp_packet_generator packet_generator (
        .i_clk(i_txclk),
        .i_arst(i_arst),
        
        .m_axis_tvalid(valid),
        .m_axis_tdata(data),
        .m_axis_tready(ready),
        .m_axis_tlast(last),

        .s_axis_tdata(udp_data_tdata),
        .s_axis_tvalid(udp_data_tvalid),
        .s_axis_tready(udp_data_tready),
        .s_axis_tlast(udp_data_tlast),
        .s_axis_tlen(udp_data_tlength)
    );

    dummy_udp_data_stream udp_data_stream_inst(
        .i_clk(i_txclk),
        .i_arst(i_arst),

        .m_axis_tvalid(udp_data_tvalid),
        .m_axis_tdata(udp_data_tdata),
        .m_axis_tready(udp_data_tready),
        .m_axis_tlast(udp_data_tlast),
        .m_axis_tlength(udp_data_tlength)
    );

endmodule