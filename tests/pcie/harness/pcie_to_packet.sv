module pcie_to_packet (
    input wire i_clk,
    input wire i_arst,

    output wire [3:0] TXC,
    output wire [31:0] TXD,

    input wire [255:0] pcie_axis_tdata,
    input wire [31:0]  pcie_axis_tkeep,
    input wire         pcie_axis_tvalid,
    input wire         pcie_axis_tlast,
    output wire        pcie_axis_tready
);

    wire [31:0] udp_axis_tdata;
    wire [3:0] udp_axis_tkeep;
    wire [15:0] udp_axis_tlength;
    wire udp_axis_tvalid;
    wire udp_axis_tready;
    wire udp_axis_tlast;

    mac mac_inst(
        .i_txclk(i_clk),
        .i_arst(i_arst),
        .o_TXD(TXD),
        .o_TXC(TXC),
        .i_rxclk(0),
        .i_RXD(0),
        .i_RXC(0),

        .udp_data_tdata(udp_axis_tdata),
        .udp_data_tkeep(udp_axis_tkeep),
        .udp_data_tvalid(udp_axis_tvalid),
        .udp_data_tready(udp_axis_tready),
        .udp_data_tlast(udp_axis_tlast),
        .udp_data_tlength(udp_axis_tlength)
    );

    pcie_to_data_stream pcie_conv_inst (
        .pcie_axis_clk(i_clk),
        .pcie_axis_arstn(~i_arst),
        
        .pcie_axis_tdata(pcie_axis_tdata),
        .pcie_axis_tvalid(pcie_axis_tvalid),
        .pcie_axis_tkeep(pcie_axis_tkeep),
        .pcie_axis_tlast(pcie_axis_tlast),
        .pcie_axis_tready(pcie_axis_tready),

        .eth_axis_clk(i_clk),
        .eth_axis_arstn(~i_arst),
        
        .eth_axis_tdata(udp_axis_tdata),
        .eth_axis_tvalid(udp_axis_tvalid),
        .eth_axis_tkeep(udp_axis_tkeep),
        .eth_axis_tlast(udp_axis_tlast),
        .eth_axis_tready(udp_axis_tready),
        .data_length(udp_axis_tlength)
    );

endmodule