module pcie_header_decode (
    input wire axis_clk,
    input wire axis_arstn,

    input wire [255:0] s_axis_tdata,
    input wire         s_axis_tvalid,
    input wire         s_axis_tlast,
    output wire        s_axis_tready,

    output reg [15:0] length,
    output reg        header_valid
);

    initial header_valid = 0;
    always_ff @(posedge axis_clk or negedge axis_arstn)
    if (!axis_arstn)
        header_valid <= 0;
    else if (header_valid & s_axis_tlast)
        header_valid <= 0;
    else if (!header_valid & s_axis_tvalid)
        header_valid <= 1;

    assign s_axis_tready = !header_valid;

    initial length = 0;
    always_ff @(posedge axis_clk or negedge axis_arstn)
    if (!axis_arstn)
        length <= 0;
    else if (s_axis_tready & s_axis_tvalid)
        length <= {s_axis_tdata[7:0], s_axis_tdata[15:8]};

endmodule