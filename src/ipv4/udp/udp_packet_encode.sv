`default_nettype none
module udp_packet_encode #(

) (
    input  wire i_clk,
    input  wire i_arst,

    input  wire  [31:0] s_axis_tdata,
    input  wire         s_axis_tvalid, // TValid being asserted also means sideband is valid
    output logic        s_axis_tready,
    input  wire         s_axis_tlast,

    output logic [31:0] m_axis_tdata,
    output logic        m_axis_tvalid,
    input  wire         m_axis_tready,
    output logic        m_axis_tlast,

    // Sideband signals
    input  wire  [15:0] source_port, // Can be 0 if UDP response is not needed
    input  wire  [15:0] destination_port,
    input  wire  [15:0] data_length
);
    localparam X_IDLE = 2'd0;
    localparam X_HEAD = 2'd1;
    localparam X_DATA = 2'd2;

    reg [1:0] current_state = X_IDLE;
    reg [1:0] next_state;

    always_ff @(posedge i_clk or posedge i_arst)
    if (i_arst)
        current_state <= X_IDLE;
    else
        current_state <= next_state;

    always_comb
    case (current_state)
        X_IDLE: next_state = m_axis_tvalid & m_axis_tready ? X_HEAD : X_IDLE;
        X_HEAD: next_state = X_DATA;
        X_DATA: next_state = s_axis_tlast ? X_IDLE : X_DATA;
        default: next_state = X_IDLE;
    endcase

    wire [15:0] full_length = data_length + 16'd8;

    always_comb begin
        m_axis_tvalid = s_axis_tvalid;
        m_axis_tlast = s_axis_tlast;
        
        case (current_state)
        X_IDLE: begin
            m_axis_tdata = {destination_port[7:0], destination_port[15:8], source_port[7:0], source_port[15:8]};
            s_axis_tready = 0;
        end
        X_HEAD: begin
            m_axis_tdata = {16'd0, full_length[7:0], full_length[15:8]};
            s_axis_tready = 0;
        end
        X_DATA: begin
            m_axis_tdata = s_axis_tdata;
            s_axis_tready = 1;
        end
        default: begin
            m_axis_tdata = 0;
            s_axis_tready = 0;
        end
        endcase
    end
endmodule