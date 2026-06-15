module tb_ipv4_loopback (
    input wire i_clk,
    input wire i_arst,

    input  wire  [31:0] s_axis_tdata,
    input  wire  [ 3:0] s_axis_tkeep,
    input  wire         s_axis_tvalid,
    output logic        s_axis_tready,
    input  wire         s_axis_tlast,
    input  wire  [15:0] s_axis_tlen,

    output logic [31:0] m_axis_tdata,
    output logic [ 3:0] m_axis_tkeep,
    output logic        m_axis_tvalid,
    input  wire         m_axis_tready,
    output logic        m_axis_tlast,
    output wire  [15:0] m_axis_tlen
);

    wire encoded_tvalid, encoded_tready, encoded_tlast;
    wire [31:0] encoded_tdata;
    wire [ 3:0] encoded_tkeep;

    ipv4_udp_packet_generator generation_inst (
        .i_clk(i_clk),
        .i_arst(i_arst),

        .s_axis_tdata(s_axis_tdata),
        .s_axis_tkeep(s_axis_tkeep),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .s_axis_tlast(s_axis_tlast),
        .s_axis_tlen(s_axis_tlen),

        .m_axis_tdata(encoded_tdata),
        .m_axis_tkeep(encoded_tkeep),
        .m_axis_tvalid(encoded_tvalid),
        .m_axis_tready(encoded_tready),
        .m_axis_tlast(encoded_tlast)
    );

    ipv4_udp_packet_decoder decoder_inst (
        .i_clk(i_clk),
        .i_arst(i_arst),

        .s_axis_tdata(encoded_tdata),
        .s_axis_tvalid(encoded_tvalid),
        .s_axis_tready(encoded_tready),
        .s_axis_tlast(encoded_tlast),

        .m_axis_tdata(m_axis_tdata),
        .m_axis_tkeep(m_axis_tkeep),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready),
        .m_axis_tlast(m_axis_tlast),
        .m_axis_tlen(m_axis_tlen)
    );

endmodule