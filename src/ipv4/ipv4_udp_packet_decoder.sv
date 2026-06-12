module ipv4_udp_packet_decoder (
    input wire i_clk,
    input wire i_arst,

    input  wire  [31:0] s_axis_tdata,
    input  wire         s_axis_tvalid,
    output logic        s_axis_tready,
    input  wire         s_axis_tlast,

    output logic [31:0] m_axis_tdata,
    output logic        m_axis_tvalid,
    input  wire         m_axis_tready,
    output logic        m_axis_tlast,
    output logic [15:0] m_axis_tlen
);

    wire header_tvalid, header_tready, header_tlast;
    wire [31:0] header_tdata;
    wire data_tvalid, data_tready, data_tlast;
    wire [31:0] data_tdata;

    ipv4_header_remove header_remove_inst (
        .i_clk(i_clk),
        .i_arst(i_arst),

        .s_axis_tdata(s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .s_axis_tlast(s_axis_tlast),

        .header_axis_tdata(header_tdata),
        .header_axis_tvalid(header_tvalid),
        .header_axis_tready(header_tready),
        .header_axis_tlast(header_tlast),

        .data_axis_tdata(data_tdata),
        .data_axis_tvalid(data_tvalid),
        .data_axis_tready(data_tready),
        .data_axis_tlast(data_tlast)
    );

    ipv4_header_decode header_decode_inst (
        .i_clk(i_clk),
        .i_arst(i_arst),

        .s_axis_tdata(header_tdata),
        .s_axis_tvalid(header_tvalid),
        .s_axis_tready(header_tready),
        .s_axis_tlast(header_tlast),

        .decode_done(),
        .header_valid(),

        .packet_length(),
        .identification(),
        .protocol(),
        .source_address(),
        .destination_address()
    );

    udp_packet_decode packet_decode_inst (
        .i_clk(i_clk),
        .i_arst(i_arst),

        .s_axis_tdata(data_tdata),
        .s_axis_tvalid(data_tvalid),
        .s_axis_tready(data_tready),
        .s_axis_tlast(data_tlast),

        .m_axis_tdata(m_axis_tdata),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready),
        .m_axis_tlast(m_axis_tlast),

        .source_port(),
        .destination_port(),
        .data_length(m_axis_tlen)
    );

endmodule