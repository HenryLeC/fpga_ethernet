module mac (
    input  wire        i_txclk,
    input  wire        i_arst,
    output reg  [31:0] o_TXD,
    output reg  [3:0]  o_TXC,

    input  wire        i_rxclk,
    input  wire [31:0] i_RXD,
    input  wire [3:0]  i_RXC,

    input  wire [31:0] udp_data_tdata,
    input  wire [15:0] udp_data_tlength,
    input  wire [ 3:0] udp_data_tkeep,
    output wire udp_data_tready,
    input  wire udp_data_tvalid,
    input  wire udp_data_tlast
);

    // wire [31:0] udp_data_tdata;
    // wire [15:0] udp_data_tlength;
    // wire [ 3:0] udp_data_tkeep;
    // wire udp_data_tready;
    // wire udp_data_tvalid;
    // wire udp_data_tlast;

    wire vio_reset;

    mac_vio mac_vio_inst (
        .clk(i_txclk),
        .probe_out0(vio_reset),
        .probe_out1()
    );

    wire [31:0] RXD_sync;
    wire [3:0]  RXC_sync;
    (* mark_debug = "true" *) wire o_empty;
    receive_synchronizer synch_inst (
        .i_txclk(i_txclk),
        .i_rxclk(i_rxclk),

        .i_RXD(i_RXD),
        .i_RXC(i_RXC),

        .o_RXD(RXD_sync),
        .o_RXC(RXC_sync),
        .o_empty(o_empty)
    );

    (* mark_debug = "true" *) wire [ 3:0] o_TXC_dbg = o_TXC;
    (* mark_debug = "true" *) wire [31:0] o_TXD_dbg = o_TXD;
    (* mark_debug = "true" *) wire [ 3:0] RXC_dbg = RXC_sync;
    (* mark_debug = "true" *) wire [31:0] RXD_dbg = RXD_sync;

    sfp_ila sfp_ila (
        .clk(i_txclk),
        .probe0(o_TXC_dbg),
        .probe1(o_TXD_dbg),
        .probe2(RXC_dbg),
        .probe3(RXD_dbg),
        .probe4(o_empty)
    );

    wire [31:0] r_frame_tdata;
    wire [ 3:0] r_frame_tkeep;
    wire        r_frame_tvalid, r_frame_tlast, r_frame_tinvalid;

    frame_decoder frame_decoder_inst (
        .i_clk(i_txclk),
        .i_arst(i_arst | vio_reset),

        .i_RXD(RXD_sync),
        .i_RXC(RXC_sync),

        .m_axis_tvalid(r_frame_tvalid),
        .m_axis_tdata(r_frame_tdata),
        .m_axis_tkeep(r_frame_tkeep),
        .m_axis_tlast(r_frame_tlast),
        .m_axis_tinvalid(r_frame_tinvalid)
    );

    wire [31:0] recv_tdata;
    wire [15:0] recv_tlen;
    wire [ 3:0] recv_tkeep;
    wire        recv_tvalid, recv_tready, recv_tlast;

    ipv4_udp_packet_decoder decoder_inst (
        .i_clk(i_txclk),
        .i_arst(i_arst | vio_reset),

        .s_axis_tdata(r_frame_tdata),
        .s_axis_tvalid(r_frame_tvalid),
        .s_axis_tready(),
        .s_axis_tlast(r_frame_tlast),

        .m_axis_tdata(recv_tdata),
        .m_axis_tkeep(recv_tkeep),
        .m_axis_tvalid(recv_tvalid),
        .m_axis_tready(recv_tready),
        .m_axis_tlast(recv_tlast),
        .m_axis_tlen(recv_tlen)
    );

    // sync_fifo #(
    //     .DATA_WIDTH(32+16+4+1),
    //     .ADDRESS_WIDTH(5)
    // ) fifo_buffer (
    //     .i_clk(i_txclk),
    //     .i_arst(i_arst | vio_reset),

    //     .s_tdata({recv_tlen, recv_tlast, recv_tkeep, recv_tdata}),
    //     .s_tvalid(recv_tvalid),
    //     .s_tready(recv_tready),

    //     .m_tdata({udp_data_tlength, udp_data_tlast, udp_data_tkeep, udp_data_tdata}),
    //     .m_tvalid(udp_data_tvalid),
    //     .m_tready(udp_data_tready)
    // );


    ipv4_udp_packet_generator packet_generator (
        .i_clk(i_txclk),
        .i_arst(i_arst | vio_reset),
        
        .m_axis_tvalid(valid),
        .m_axis_tkeep(keep),
        .m_axis_tdata(data),
        .m_axis_tready(ready),
        .m_axis_tlast(last),

        .s_axis_tdata(udp_data_tdata),
        .s_axis_tkeep(udp_data_tkeep),
        .s_axis_tvalid(udp_data_tvalid),
        .s_axis_tready(udp_data_tready),
        .s_axis_tlast(udp_data_tlast),
        .s_axis_tlen(udp_data_tlength)
    );

    wire valid, last, ready;
    wire [31:0] data;
    wire [ 3:0] keep;

    wire [31:0] TXD;
    wire [ 3:0] TXC;

    frame_encoder frame_encoder_inst (
        .i_clk(i_txclk),
        .i_arst(i_arst | vio_reset),

        .i_clientdata(data),
        .i_clientdata_keep(keep),
        .i_clientdata_valid(valid),
        .i_last(last),
        .o_ready(ready),

        .TXC(TXC),
        .TXD(TXD)
    );

    always_ff @(posedge i_txclk) begin
        o_TXC <= TXC;
        o_TXD <= TXD;
    end

endmodule