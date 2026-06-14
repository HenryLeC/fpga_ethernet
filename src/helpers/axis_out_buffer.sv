module axis_out_buffer #(
    parameter DATA_WIDTH = 32
) (
    input wire i_clk,
    input wire i_arst,

    input  wire  [DATA_WIDTH-1:0] s_axis_tdata,
    input  wire                   s_axis_tvalid,
    input  wire                   s_axis_tlast,
    output logic                  s_axis_tready,

    output logic [DATA_WIDTH-1:0] m_axis_tdata,
    output logic                  m_axis_tvalid,
    output logic                  m_axis_tlast,
    input  wire                   m_axis_tready
);
    reg [DATA_WIDTH-1:0] data;
    reg valid, last;

    wire int_ready = m_axis_tready | !valid;

    always_ff @(posedge i_clk or posedge i_arst)
    if(i_arst) begin
        data <= 0;
        valid <= 0;
        last <= 0;
    end
    else if (int_ready) begin
        data <= s_axis_tdata;
        valid <= s_axis_tvalid;
        last <= s_axis_tlast;
    end

    assign m_axis_tdata = data;
    assign m_axis_tvalid = valid;
    assign m_axis_tlast = last;
    assign s_axis_tready = int_ready;

endmodule