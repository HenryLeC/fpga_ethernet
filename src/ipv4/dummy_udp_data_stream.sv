module dummy_udp_data_stream (
    input wire i_clk,
    input wire i_arst,

    output logic [31:0] m_axis_tdata,
    output logic        m_axis_tvalid,
    output logic        m_axis_tlast,
    input  wire         m_axis_tready,
    output logic [15:0] m_axis_tlength        
);

    logic [31:0] data [0:2];

    initial begin
        data[0] = 32'h48454C4C;
        data[1] = 32'h4F20574F;
        data[2] = 32'h524C4421;
    end

    logic [1:0] pointer = 0;

    always_ff @(posedge i_clk or posedge i_arst)
    if (i_arst)
        pointer <= 0;
    else if (m_axis_tvalid & m_axis_tready) begin
        if (pointer == 2)
            pointer <= 0;
        else
            pointer <= pointer + 1;
    end

    assign m_axis_tdata = data[pointer];
    assign m_axis_tlast = pointer == 2;
    assign m_axis_tlength = 16'd12;
    assign m_axis_tvalid = 1;

endmodule