`include "code_defs.svh"
`default_nettype none
module frame_decoder #(
    parameter PORT_MAC_ADDR = 48'h000000000000,
    parameter PORT_MAX_MASK = 48'h000000000000
) (
    input  wire        i_clk,
    input  wire        i_arst,

    input  wire [31:0] i_RXD,
    input  wire [ 3:0] i_RXC,

    output logic        m_axis_tvalid,
    output logic [31:0] m_axis_tdata,
    output logic [ 3:0] m_axis_tkeep,
    output logic        m_axis_tlast,
    output logic        m_axis_tinvalid // if asserted during tlast means the whole transmission was invalid
);
    localparam MASKED_MAC = PORT_MAC_ADDR & PORT_MAX_MASK;

    import code_defs::*;

    localparam X_IDLE    = 2'd0;
    localparam X_START   = 2'd1;
    localparam X_ADDRESS = 2'd2;
    localparam X_DATA    = 2'd3;

    reg   [1:0] state = X_IDLE;
    logic [1:0] next_state;

    reg   [2:0] proc_count = 0;
    reg  [47:0] dest_mac   = 0;

    wire start_detected = i_RXC[0] & (i_RXD[7:0] == RS_START);
    wire end_detected   = (i_RXC[0] & i_RXD[7:0] == RS_TERM) | (i_RXC[1] & i_RXD[15:8] == RS_TERM) | (i_RXC[2] & i_RXD[23:16] == RS_TERM) | (i_RXC[3] & i_RXD[31:24] == RS_TERM);
    wire recv_address_match = &dest_mac | ((dest_mac & PORT_MAX_MASK) == MASKED_MAC);

    wire [31:0] crc;
    reg crc_check;

    crc_calc crc_calc_inst (
        .i_clk(i_clk),
        .i_arst(state == X_START),
        .i_data(i_RXD),
        .i_valid(~i_RXC),
        .o_crc(crc)
    );

    always_comb
    case (state)
        X_IDLE:    next_state = start_detected ? X_START : X_IDLE;
        X_START:   next_state = X_ADDRESS;
        X_ADDRESS: next_state = proc_count == 2 ? recv_address_match ? X_DATA : X_IDLE : X_ADDRESS;
        X_DATA:    next_state = end_detected ? X_IDLE : X_DATA;
        default:   next_state = X_IDLE;
    endcase

    always_ff @(posedge i_clk or posedge i_arst)
    if (i_arst)
        state <= X_IDLE;
    else
        state <= next_state;

    always_ff @(posedge i_clk or posedge i_arst)
    if (i_arst)
        proc_count <= 0;
    else
        proc_count <= (state == next_state) ? proc_count + 1 : 0;

    always_ff @(posedge i_clk or posedge i_arst)
    if (i_arst)
        crc_check <= 0;
    else
        crc_check <= crc == i_RXD;

    always_ff @(posedge i_clk or posedge i_arst)
    if (i_arst)
        dest_mac <= 0;
    else if (state == X_ADDRESS)
    case (proc_count)
        3'd0: dest_mac <= {i_RXD[7:0], i_RXD[15:8], i_RXD[23:16], i_RXD[31:24], {2{8'h00}}};
        3'd1: dest_mac <= {dest_mac[47:16], i_RXD[7:0], i_RXD[15:8]};
        default: begin end
    endcase

    always_comb begin
        m_axis_tvalid   = state == X_DATA;
        m_axis_tdata    = i_RXD;
        m_axis_tkeep    = ~i_RXC;
        m_axis_tlast    = end_detected & m_axis_tvalid;
        m_axis_tinvalid = !crc_check;
    end

endmodule