module ipv4_udp_packet_decoder (
    input wire i_clk,
    input wire i_arst,

    input  wire  [63:0] s_axis_tdata,
    input  wire  [ 7:0] s_axis_tkeep,
    input  wire         s_axis_tvalid,
    output logic        s_axis_tready,
    input  wire         s_axis_tlast,

    output logic [63:0] m_axis_tdata,
    output logic [ 7:0] m_axis_tkeep,
    output logic        m_axis_tvalid,
    input  wire         m_axis_tready,
    output logic        m_axis_tlast,
    output logic [15:0] m_axis_tlen
);

    localparam X_REST = 2'd0;
    localparam X_PROC = 2'd1;
    localparam X_LOCK = 2'd2;

    wire header_done, header_valid;
    wire [7:0] header_protocol;

    logic [1:0] current_state, next_state;
    always_ff @(posedge i_clk or posedge i_arst)
    if (i_arst)
        current_state <= X_REST;
    else
        current_state <= next_state;

    always_comb
    case (current_state)
    X_REST: next_state = X_PROC;
    X_PROC: next_state = header_done & (!header_valid | header_protocol != 8'h11) ? X_LOCK : X_PROC;
    X_LOCK: next_state = s_axis_tvalid ? X_LOCK : X_REST;
    default: next_state = X_PROC;
    endcase

    wire header_tvalid, header_tready, header_tlast;
    wire [63:0] header_tdata;
    wire [ 1:0] header_tkeep;
    wire data_tvalid, data_tready, data_tlast;
    wire [63:0] data_tdata;
    wire [ 7:0] data_tkeep;
    ipv4_header_remove header_remove_inst (
        .i_clk(i_clk),
        .i_arst(i_arst),

        .s_axis_tdata(s_axis_tdata),
        .s_axis_tkeep(s_axis_tkeep),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .s_axis_tlast(s_axis_tlast),

        .header_axis_tdata(header_tdata),
        .header_axis_tkeep(header_tkeep),
        .header_axis_tvalid(header_tvalid),
        .header_axis_tready(header_tready),
        .header_axis_tlast(header_tlast),

        .data_axis_tdata(data_tdata),
        .data_axis_tkeep(data_tkeep),
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

        .header_tkeep(header_tkeep),

        .decode_done(header_done),
        .header_valid(header_valid),

        .packet_length(),
        .identification(),
        .protocol(header_protocol),
        .source_address(),
        .destination_address()
    );

    wire packet_valid, packet_last;

    udp_packet_decode packet_decode_inst (
        .i_clk(i_clk),
        .i_arst(i_arst | (current_state == X_LOCK)),

        .s_axis_tdata(data_tdata),
        .s_axis_tkeep(data_tkeep),
        .s_axis_tvalid(data_tvalid),
        .s_axis_tready(data_tready),
        .s_axis_tlast(data_tlast),

        .m_axis_tdata(m_axis_tdata),
        .m_axis_tkeep(m_axis_tkeep),
        .m_axis_tvalid(packet_valid),
        .m_axis_tready(m_axis_tready),
        .m_axis_tlast(m_axis_tlast),

        .source_port(),
        .destination_port(),
        .data_length(m_axis_tlen)
    );

    assign m_axis_tvalid = packet_valid & (current_state != X_LOCK);

endmodule
