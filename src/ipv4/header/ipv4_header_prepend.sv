module ipv4_header_prepend #(

) (
    input wire i_clk,
    input wire i_arst,

    input  wire  [31:0] header_axis_tdata,
    input  wire         header_axis_tvalid,
    output logic        header_axis_tready,
    input  wire         header_axis_tlast,

    input  wire  [31:0] data_axis_tdata,
    input  wire         data_axis_tvalid,
    output logic        data_axis_tready,
    input  wire         data_axis_tlast,

    output logic        m_axis_tvalid,
    output logic [31:0] m_axis_tdata,
    input  wire         m_axis_tready,
    output logic        m_axis_tlast

);
    localparam X_IDLE = 2'd0;
    localparam X_HEAD = 2'd1;
    localparam X_BODY = 2'd2;

    logic [1:0] current_state, next_state;

    initial current_state = X_IDLE;
    always_ff @(posedge i_clk or posedge i_arst)
    if (i_arst)
        current_state <= X_IDLE;
    else
        current_state <= next_state;

    always_comb
    case (current_state)
    X_IDLE: next_state = header_axis_tvalid & m_axis_tready ? X_HEAD : X_IDLE;
    X_HEAD: next_state = header_axis_tlast ? X_BODY : X_HEAD;
    X_BODY: next_state = data_axis_tlast_prev ? X_IDLE : X_BODY;
    default: next_state = X_IDLE;
    endcase

    logic data_axis_tlast_prev;
    always_ff @(posedge i_clk)
        data_axis_tlast_prev <= data_axis_tlast;

    always_comb begin
        m_axis_tlast = current_state == X_BODY ? data_axis_tlast_prev : 0;
        m_axis_tvalid = |current_state | header_axis_tvalid;
        case (current_state)
        X_IDLE: begin
            m_axis_tdata = header_axis_tvalid ? header_axis_tdata : 0;
            header_axis_tready = header_axis_tvalid & m_axis_tready ? 1 : 0;
            data_axis_tready   = 0;
        end
        X_HEAD: begin
            m_axis_tdata = header_axis_tlast ? {data_axis_tdata[15:0], header_axis_tdata[15:0]} : header_axis_tdata;
            header_axis_tready = 1;
            data_axis_tready   = header_axis_tlast ? 1 : 0;
        end
        X_BODY: begin
            m_axis_tdata = {data_axis_tdata[15:0], data_upper_bytes};
            header_axis_tready = 0;
            data_axis_tready   = 1;
        end
        default: begin
            m_axis_tdata = 0;
            header_axis_tready = 0;
            data_axis_tready   = 0;
        end
        endcase
    end

    logic [15:0] data_upper_bytes = 0;
    always_ff @(posedge i_clk or i_arst)
    if (i_arst)
        data_upper_bytes <= 0;
    else if (data_axis_tready)
        data_upper_bytes <= data_axis_tdata[31:16];
endmodule