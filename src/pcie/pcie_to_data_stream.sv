module pcie_to_data_stream (
    input wire pcie_axis_clk,
    input wire pcie_axis_arstn,

    input  wire [255:0] pcie_axis_tdata,
    input  wire         pcie_axis_tvalid,
    input  wire [ 31:0] pcie_axis_tkeep,
    input  wire         pcie_axis_tlast,
    output wire         pcie_axis_tready,

    input wire eth_axis_clk,
    input wire eth_axis_arstn,

    output wire [31:0] eth_axis_tdata,
    output wire        eth_axis_tvalid,
    output wire [ 3:0] eth_axis_tkeep,
    output wire        eth_axis_tlast,
    input  wire        eth_axis_tready,

    output wire [15:0] data_length
);

    wire sync_full, sync_empty;
    assign pcie_axis_tready = ~sync_full;
    async_fifo #(
        .DATA_WIDTH(256+32+1)
    ) pcie_eth_sync_inst (
        .i_wclk(pcie_axis_clk),
        .i_wrst(~pcie_axis_arstn),
        .i_wr(pcie_axis_tvalid),
        .i_wdata({pcie_axis_tlast, pcie_axis_tkeep, pcie_axis_tdata}),
        .o_wfull(sync_full),

        .i_rclk(eth_axis_clk),
        .i_rrst(~eth_axis_arstn),
        .i_rd(pcie_axis_tready_sync),
        .o_rdata({pcie_axis_tlast_sync, pcie_axis_tkeep_sync, pcie_axis_tdata_sync}),
        .o_rempty(sync_empty)
    );

    wire [255:0] pcie_axis_tdata_sync;
    wire         pcie_axis_tvalid_sync = ~sync_empty;
    wire [ 31:0] pcie_axis_tkeep_sync;
    wire         pcie_axis_tlast_sync;
    wire         pcie_axis_tready_sync = header_valid ? width_convert_ready : header_ready;

    wire header_valid;
    wire data_valid;

    wire width_convert_ready, header_ready;

    axis_width_convert width_convert_inst (
        .axis_clk(eth_axis_clk),
        .axis_arstn(eth_axis_arstn),

        .s_axis_tdata(pcie_axis_tdata_sync),
        .s_axis_tvalid(pcie_axis_tvalid_sync & header_valid),
        .s_axis_tkeep(pcie_axis_tkeep_sync),
        .s_axis_tlast(pcie_axis_tlast_sync),
        .s_axis_tready(width_convert_ready),

        .m_axis_tdata(eth_axis_tdata),
        .m_axis_tvalid(data_valid),
        .m_axis_tkeep(eth_axis_tkeep),
        .m_axis_tlast(eth_axis_tlast),
        .m_axis_tready(eth_axis_tready)
    );

    pcie_header_decode header_decode_inst (
        .axis_clk(eth_axis_clk),
        .axis_arstn(eth_axis_arstn),

        .s_axis_tdata(pcie_axis_tdata_sync),
        .s_axis_tvalid(pcie_axis_tvalid_sync),
        .s_axis_tlast(pcie_axis_tlast_sync),
        .s_axis_tready(header_ready),

        .length(data_length),
        .header_valid(header_valid)
    );

    assign eth_axis_tvalid = data_valid;

endmodule