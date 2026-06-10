module ipv4_header_remove #(

) (
    input wire i_clk,
    input wire i_arst,

    input  wire  [31:0] s_axis_tdata,
    input  wire         s_axis_tvalid,
    output logic        s_axis_tready,
    input  wire         s_axis_tlast,

    output logic [31:0] header_axis_tdata,
    output logic        header_axis_tvalid,
    input  wire         header_axis_tready,
    input  wire         header_axis_tlast, // This is backwards, see ipv4_header_decode

    output logic [31:0] data_axis_tdata,
    output logic        data_axis_tvalid,
    input  wire         data_axis_tready,
    output logic        data_axis_tlast
);

    localparam X_IDLE = 2'd0;
    localparam X_HEAD = 2'd1;
    localparam X_BODY = 2'd2;
    localparam X_LAST = 2'd3;

    logic [1:0] current_state, next_state;

    initial current_state = X_IDLE;
    always_ff @(posedge i_clk or posedge i_arst)
    if (i_arst)
        current_state <= X_IDLE;
    else
        current_state <= next_state;

    always_comb
    case (current_state)
    X_IDLE: next_state = s_axis_tvalid ? X_HEAD : X_IDLE;
    X_HEAD: next_state = header_axis_tlast ? X_BODY : X_HEAD;
    X_BODY: next_state = s_axis_tlast ? X_LAST : X_BODY;
    X_LAST: next_state = X_IDLE;
    endcase

    always_comb
    case (current_state)
    X_IDLE: begin
        header_axis_tdata = s_axis_tdata;
        header_axis_tvalid = s_axis_tvalid;
        data_axis_tdata = 0;
        data_axis_tvalid = 0;
    end
    X_HEAD: begin
        header_axis_tdata = s_axis_tdata;
        header_axis_tvalid = 1;
        data_axis_tdata = 0;
        data_axis_tvalid = 0;
    end
    X_BODY: begin
        header_axis_tdata = 0;
        header_axis_tvalid = 0;
        data_axis_tdata = {s_axis_tdata[15:0], data_lower_bytes};
        data_axis_tvalid = 1;
    end
    X_LAST: begin
        header_axis_tdata = 0;
        header_axis_tvalid = 0;
        data_axis_tdata = {16'h0, data_lower_bytes};
        data_axis_tvalid = 1;
    end
    endcase

    logic [15:0] data_lower_bytes = 0;
    always_ff @(posedge i_clk or posedge i_arst)
    if (i_arst)
        data_lower_bytes <= 0;
    else if (data_axis_tvalid | header_axis_tlast)
        data_lower_bytes <= s_axis_tdata[31:16];

    assign data_axis_tlast = current_state == X_LAST;
    assign s_axis_tready = 1;
endmodule