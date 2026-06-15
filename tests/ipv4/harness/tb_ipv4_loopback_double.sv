module tb_ipv4_loopback_double (
    input wire i_clk,
    input wire i_arst,

    input  wire  [31:0] s_axis_tdata,
    input  wire  [ 3:0] s_axis_tkeep,
    input  wire         s_axis_tvalid,
    output wire         s_axis_tready,
    input  wire         s_axis_tlast,
    input  wire  [15:0] s_axis_tlen,

    output wire  [31:0] m_axis_tdata,
    output wire  [ 3:0] m_axis_tkeep,
    output wire         m_axis_tvalid,
    input  wire         m_axis_tready,
    output wire         m_axis_tlast,
    output wire  [15:0] m_axis_tlen
);

    wire write_tvalid, write_tready, write_tlast;
    wire [31:0] write_tdata;
    wire [ 3:0] write_tkeep;
    wire [15:0] write_tlen;
    
    wire read_tvalid, read_tready, read_tlast;
    wire [31:0] read_tdata;
    wire [ 3:0] read_tkeep;
    wire [15:0] read_tlen;

    tb_ipv4_loopback loopback_1 (
        .i_clk(i_clk),
        .i_arst(i_arst),

        .s_axis_tdata(s_axis_tdata),
        .s_axis_tkeep(s_axis_tkeep),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .s_axis_tlast(s_axis_tlast),
        .s_axis_tlen(s_axis_tlen),

        .m_axis_tdata(write_tdata),
        .m_axis_tkeep(write_tkeep),
        .m_axis_tvalid(write_tvalid),
        .m_axis_tready(write_tready),
        .m_axis_tlast(write_tlast),
        .m_axis_tlen(write_tlen)
    );

    sync_fifo #(
        .DATA_WIDTH(32+16+4+1)
    ) fifo_buffer (
        .i_clk(i_clk),
        .i_arst(i_arst),

        .s_tdata({write_tlen, write_tlast, write_tkeep, write_tdata}),
        .s_tvalid(write_tvalid),
        .s_tready(write_tready),

        .m_tdata({read_tlen, read_tlast, read_tkeep, read_tdata}),
        .m_tvalid(read_tvalid),
        .m_tready(read_tready)
    );



    tb_ipv4_loopback loopback_2 (
        .i_clk(i_clk),
        .i_arst(i_arst),

        .s_axis_tdata(read_tdata),
        .s_axis_tkeep(read_tkeep),
        .s_axis_tvalid(read_tvalid),
        .s_axis_tready(read_tready),
        .s_axis_tlast(read_tlast),
        .s_axis_tlen(read_tlen),

        .m_axis_tdata(m_axis_tdata),
        .m_axis_tkeep(m_axis_tkeep),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready),
        .m_axis_tlast(m_axis_tlast),
        .m_axis_tlen(m_axis_tlen)
    );

endmodule