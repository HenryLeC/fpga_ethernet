`default_nettype none
module udp_packet_decode #(

) (
    input  wire i_clk,
    input  wire i_arst,

    input  wire  [63:0] s_axis_tdata,
    input  wire  [ 7:0] s_axis_tkeep,
    input  wire         s_axis_tvalid,
    output logic        s_axis_tready,
    input  wire         s_axis_tlast,

    output logic [63:0] m_axis_tdata,
    output logic [ 7:0] m_axis_tkeep,
    output logic        m_axis_tvalid, // TValid being asserted also means sideband is valid
    input  wire         m_axis_tready, // Unconnected (can add buffer for backpressure support)
    output logic        m_axis_tlast,

    // Sideband signals
    output logic [15:0] source_port,
    output logic [15:0] destination_port,
    output logic [15:0] data_length
);
    localparam X_IDLE = 2'd0;
    localparam X_DATA = 2'd2;
    localparam X_LOCK = 2'd3;

    reg [1:0] current_state = X_IDLE;
    reg [1:0] next_state;

    always_ff @(posedge i_clk or posedge i_arst)
    if (i_arst)
        current_state <= X_IDLE;
    else
        current_state <= next_state;

    always_comb
    case (current_state)
        X_IDLE: next_state = s_axis_tvalid ? X_DATA : X_IDLE;
        X_DATA: next_state = m_axis_tlast ? X_LOCK : X_DATA;
        X_LOCK: next_state = s_axis_tvalid ? X_LOCK : X_IDLE;
        default: next_state = X_IDLE;
    endcase

    logic [15:0] dword_counter;
    always_ff @(posedge i_clk or posedge i_arst)
    if (i_arst)
        dword_counter <= 0;
    else if (s_axis_tvalid)
        dword_counter <= dword_counter + 8;
    else
        dword_counter <= 0;

    logic [15:0] full_length;
    always_ff @(posedge i_clk or posedge i_arst)
    if (i_arst) begin
        source_port <= 0;
        destination_port <= 0;
    end else
    case (current_state)
    X_IDLE: begin
        source_port <= {s_axis_tdata[7:0], s_axis_tdata[15:8]};
        destination_port <= {s_axis_tdata[24:16], s_axis_tdata[31:25]};
        full_length <= {s_axis_tdata[39:32], s_axis_tdata[47:40]};
    end
    X_DATA: begin

    end
    default: begin

    end
    endcase

    wire [15:0] words_left = full_length - dword_counter;

    always_comb
    case (current_state)
    X_DATA: begin
        m_axis_tdata = s_axis_tdata;
        m_axis_tvalid = 1;
        case (words_left)
        8: m_axis_tkeep = 8'b11111111;
        7: m_axis_tkeep = 8'b01111111;
        6: m_axis_tkeep = 8'b00111111;
        5: m_axis_tkeep = 8'b00011111;
        4: m_axis_tkeep = 8'b00001111;
        3: m_axis_tkeep = 8'b00000111;
        2: m_axis_tkeep = 8'b00000011;
        1: m_axis_tkeep = 8'b00000001;
        0: m_axis_tkeep = 8'b00000000;
        default: m_axis_tkeep = 8'b11111111;
        endcase
        m_axis_tlast = 8 >= words_left;
    end
    default: begin
        m_axis_tdata = 0;
        m_axis_tkeep = 0;
        m_axis_tvalid = 0;
        m_axis_tlast = 0;
    end
    endcase

    assign data_length = full_length - 16'd8;
    assign s_axis_tready = 1;

endmodule
