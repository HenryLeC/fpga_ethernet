module ipv4_header_encode #(

) (
    input wire i_clk,
    input wire i_arst,
    
    output logic        m_axis_tvalid,
    output logic [31:0] m_axis_tdata,
    input  logic        m_axis_tready,
    output logic        m_axis_tlast,

    input  wire  [15:0] packet_length,
    input  wire  [15:0] identification,
    input  wire  [ 7:0] protocol,
    input  wire  [15:0] checksum,
    input  wire  [31:0] source_address,
    input  wire  [31:0] destination_address,
    input  wire         data_valid
);
    localparam X_IDLE = 1'd0;
    localparam X_DATA = 1'd1;

    reg [0:0] current_state = X_IDLE;
    reg [0:0] next_state;
    reg [2:0] dword_count = 1;

    always_ff @(posedge i_clk or posedge i_arst)
    if (i_arst)
        dword_count <= 1;
    else if (next_state & current_state & m_axis_tready)
        dword_count <= dword_count + 1;
    else
        dword_count <= 1;

    always_ff @(posedge i_clk or posedge i_arst)
    if (i_arst)
        current_state <= X_IDLE;
    else
        current_state <= next_state;

    always_comb
    case (current_state)
        X_IDLE: next_state = data_valid ? X_DATA : X_IDLE;
        X_DATA: next_state = (dword_count == 5) ? X_IDLE : X_DATA;
    endcase

    always_comb begin
        m_axis_tvalid = current_state | data_valid;
        m_axis_tlast = dword_count == 5;
        if (!current_state & !data_valid)
            m_axis_tdata = 32'h0;
        else if (!current_state & data_valid)
            m_axis_tdata = 32'h00450008; // EtherType, Version, IHL, DSCP, ECN
        else
        case (dword_count)
            3'd1: m_axis_tdata = {identification[7:0], identification[15:8], packet_length[7:0], packet_length[15:8]}; // Packet Length, Identification
            3'd2: m_axis_tdata = {protocol, 8'h40, 16'h0}; // Flags, Fragment Offset, TTL, Protocol
            3'd3: m_axis_tdata = {source_address[23:16], source_address[31:24], checksum}; // Checksum, Source Address[31:16]
            3'd4: m_axis_tdata = {destination_address[23:16], destination_address[31:24], source_address[7:0], source_address[15:8]};
            3'd5: m_axis_tdata = {16'h0, destination_address[7:0], destination_address[15:8]};
            default: m_axis_tdata = 32'h0;
        endcase
    end

endmodule