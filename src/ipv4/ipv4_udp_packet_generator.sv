module ipv4_udp_packet_generator (
    input wire i_clk,
    input wire i_arst,

    input  wire  [31:0] s_axis_tdata,
    input  wire         s_axis_tvalid,
    output logic        s_axis_tready,
    input  wire         s_axis_tlast,
    input  wire  [15:0] s_axis_tlen,

    output logic        m_axis_tvalid,
    output logic [31:0] m_axis_tdata,
    input  wire         m_axis_tready,
    output logic        m_axis_tlast
);

    wire header_tvalid, header_tready, header_tlast;
    wire [31:0] header_tdata;

    wire udp_axis_tvalid, udp_axis_tready, udp_axis_tlast;
    wire [31:0] udp_axis_tdata;

    ipv4_header_prepend header_prepend_inst (
        .i_clk(i_clk),
        .i_arst(i_arst),

        .header_axis_tdata(header_tdata),
        .header_axis_tvalid(header_tvalid),
        .header_axis_tready(header_tready),
        .header_axis_tlast(header_tlast),

        .data_axis_tdata(udp_axis_tdata),
        .data_axis_tvalid(udp_axis_tvalid),
        .data_axis_tready(udp_axis_tready),
        .data_axis_tlast(udp_axis_tlast),

        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tready(m_axis_tready),
        .m_axis_tlast(m_axis_tlast)
    );

    ipv4_header_encode header_gen_inst (
        .i_clk(i_clk),
        .i_arst(i_arst),
        
        .m_axis_tvalid(header_tvalid),
        .m_axis_tdata(header_tdata),
        .m_axis_tready(header_tready),
        .m_axis_tlast(header_tlast),

        .packet_length(s_axis_tlen + 16'd28),
        .identification(16'h1234),
        .protocol(8'd17),
        .source_address(32'h01010101),
        .destination_address(32'h0A0001FF),
        .data_valid(s_axis_tvalid)
    );

    udp_packet_encode udp_packet_encode_inst (
        .i_clk(i_clk),
        .i_arst(i_arst),

        .s_axis_tdata(s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .s_axis_tlast(s_axis_tlast),

        .m_axis_tdata(udp_axis_tdata),
        .m_axis_tvalid(udp_axis_tvalid),
        .m_axis_tready(udp_axis_tready),
        .m_axis_tlast(udp_axis_tlast),

        .source_port(16'h8080),
        .destination_port(16'h8080),
        .data_length(s_axis_tlen)
    );

endmodule