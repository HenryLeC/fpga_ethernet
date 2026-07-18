module ipv4_header_remove #(

) (
    input wire i_clk,
    input wire i_arst,

    input  wire  [63:0] s_axis_tdata,
    input  wire  [ 7:0] s_axis_tkeep,
    input  wire         s_axis_tvalid,
    output logic        s_axis_tready,
    input  wire         s_axis_tlast,

    output logic [63:0] header_axis_tdata,
    input  wire  [ 1:0] header_axis_tkeep,
    output logic        header_axis_tvalid,
    input  wire         header_axis_tready,
    input  wire         header_axis_tlast, // This is backwards, see ipv4_header_decode

    output logic [63:0] data_axis_tdata,
    output logic [ 7:0] data_axis_tkeep,
    output logic        data_axis_tvalid,
    input  wire         data_axis_tready,
    output logic        data_axis_tlast
);

    typedef enum logic [2:0] { 
        X_IDLE,
        X_HEAD,
        X_BODY_SHIFT,
        X_LAST_SHIFT,
        X_BODY_ALIGNED
     } state_t;

    state_t current_state, next_state;

    always_ff @(posedge i_clk or posedge i_arst)
    if (i_arst)
        current_state <= X_IDLE;
    else
        current_state <= next_state;

    always_comb
    case (current_state)
    X_IDLE: next_state = s_axis_tvalid ? X_HEAD : X_IDLE;
    X_HEAD: next_state = header_axis_tlast ? (
        &header_axis_tkeep ? X_BODY_ALIGNED : X_BODY_SHIFT
    ) : X_HEAD;
    X_BODY_SHIFT: next_state = s_axis_tlast ? (data_axis_tlast ? X_IDLE : X_LAST_SHIFT) : X_BODY_SHIFT;
    X_LAST_SHIFT: next_state = X_IDLE;
    X_BODY_ALIGNED: next_state = s_axis_tlast ? X_IDLE : X_BODY_ALIGNED;
    default: next_state = X_IDLE;
    endcase

    logic [31:0] last_upper_bytes = 0;
    logic [ 3:0] last_upper_keep = 0;

    always_ff @(posedge i_clk or posedge i_arst)
    if (i_arst)
        {last_upper_bytes, last_upper_keep} <= 0;
    else if (data_axis_tvalid | header_axis_tlast)
        {last_upper_bytes, last_upper_keep} <= {s_axis_tdata[63:32], s_axis_tkeep[7:4]};

    always_comb
    case (current_state)
    X_IDLE: begin
        header_axis_tdata = s_axis_tdata;
        header_axis_tvalid = s_axis_tvalid;
        data_axis_tdata = 0;
        data_axis_tvalid = 0;
        data_axis_tlast = 0;
        data_axis_tkeep = 0;
    end
    X_HEAD: begin
        header_axis_tdata = s_axis_tdata;
        header_axis_tvalid = 1;
        data_axis_tdata = 0;
        data_axis_tvalid = 0;
        data_axis_tlast = 0;
        data_axis_tkeep = 0;
    end
    X_BODY_SHIFT: begin
        header_axis_tdata = 0;
        header_axis_tvalid = 0;
        data_axis_tdata = {s_axis_tdata[31:0], last_upper_bytes};
        data_axis_tvalid = 1;
        data_axis_tlast = ~(|s_axis_tkeep[7:4]);
        data_axis_tkeep = {s_axis_tkeep[3:0], last_upper_keep};
    end
    X_LAST_SHIFT: begin
        header_axis_tdata = 0;
        header_axis_tvalid = 0;
        data_axis_tdata = {32'h0, last_upper_bytes};
        data_axis_tvalid = 1;
        data_axis_tlast = 1;
        data_axis_tkeep = {4'h0, last_upper_keep};
    end
    X_BODY_ALIGNED: begin
        header_axis_tdata = 0;
        header_axis_tvalid = 1;
        data_axis_tdata = s_axis_tdata;
        data_axis_tvalid = s_axis_tvalid;
        data_axis_tlast = s_axis_tlast;
        data_axis_tkeep = 0;
    end
    default: begin
        header_axis_tdata = 0;
        header_axis_tvalid = 0;
        data_axis_tdata = 0;
        data_axis_tvalid = 0;
        data_axis_tlast = 0;
        data_axis_tkeep = 0;
    end
    endcase

    assign s_axis_tready = 1;
endmodule
