`include "code_defs.svh"
`default_nettype none
module frame_decoder #(
    parameter BYTE_LANES    = 8,

    parameter PORT_MAC_ADDR = 48'h000000000000,
    parameter PORT_MAX_MASK = 48'h000000000000
) (
    input  wire        i_clk,
    input  wire        i_arst,

    input  wire [(BYTE_LANES * 8) - 1:0] i_RXD,
    input  wire [BYTE_LANES - 1:0] i_RXC,

    output logic        m_axis_tvalid,
    output logic [(BYTE_LANES * 8) - 1:0] m_axis_tdata,
    output logic [BYTE_LANES - 1:0] m_axis_tkeep,
    output logic        m_axis_tlast,
    output logic        m_axis_tinvalid // if asserted during tlast or next cycle means the whole transmission was invalid
);

    import code_defs::*;

    typedef enum logic [2:0] 
    {
         X_IDLE     = 3'd0
        ,X_START    = 3'd1
        ,X_PREAMBLE = 3'd2
        ,X_ADDRESS  = 3'd3
        ,X_DATA    = 3'd4
    } byte_state_t;

    logic [3:0] proc_count_q;

    byte_state_t state_q [0:7];
    byte_state_t next_state_w [0:7];

    logic [(BYTE_LANES * 8) - 1:0] prev_RXD;

    always_ff @(posedge i_clk) begin
        prev_RXD <= i_RXD;
    end

    for (genvar i = 0; i < BYTE_LANES; i = i + 1) begin: state_store
    always_ff @(posedge i_clk or posedge i_arst)
    if (i_arst) begin
        state_q[i] <= X_IDLE;
    end else
        state_q[i] <= next_state_w[i];
    end

    logic [3:0] cascase_count;
    always_ff @(posedge i_clk or posedge i_arst)
    if (i_arst) begin
        proc_count_q <= 0;
    end else
        proc_count_q <= cascase_count;

    logic [7:0] term_detected, term_detected_q;
    logic [7:0] start_detected;

    always_comb begin
    for (int i = 0; i < BYTE_LANES; i = i + 1) begin: term_detection
        term_detected[i]  = i_RXC[i] & rs_code_t'(i_RXD[8*(i+1)-1 -: 8]) == RS_TERM;
        start_detected[i] = i[1:0] == 0 & i_RXC[i] & rs_code_t'(i_RXD[8*(i+1)-1 -: 8]) == RS_START;
    end
    end

    always_ff @(posedge i_clk) begin
        term_detected_q <= term_detected;
    end

    always_comb begin
    byte_state_t cascade_state; 
    // Seed the cascade with the initial state for lane 0
    cascade_state = state_q[7];
    cascase_count = proc_count_q;
    for (int i = 0; i < BYTE_LANES; i = i + 1) begin: next_state_comp
        case (cascade_state)
            X_IDLE: next_state_w[i] = start_detected[i] ? X_START : X_IDLE;
            X_START: next_state_w[i] = X_PREAMBLE;
            X_PREAMBLE: next_state_w[i] = (cascase_count == 4'd6) ? X_ADDRESS : X_PREAMBLE;
            X_ADDRESS: next_state_w[i] = (cascase_count == 4'd11) ? X_DATA : X_ADDRESS;
            X_DATA: next_state_w[i] = term_detected[i] ? X_IDLE : X_DATA;
            default: next_state_w[i] = X_IDLE;
        endcase
        cascase_count = (next_state_w[i] == cascade_state) ? cascase_count + 1 : 0;
        cascade_state = next_state_w[i];
    end
    end

    logic [7:0] is_crc_byte;
    always_comb begin
        is_crc_byte = 0;
        if (| term_detected[3:0]) begin
            case (term_detected[3:0])
                4'b1000: is_crc_byte = 8'b10000000;
                4'b0100: is_crc_byte = 8'b11000000;
                4'b0010: is_crc_byte = 8'b11100000;
                4'b0001: is_crc_byte = 8'b11110000;
                default: is_crc_byte = 0;
            endcase
        end else if (| term_detected_q) begin
            case (term_detected_q)
                8'b10000000: is_crc_byte = 8'b01111000;
                8'b01000000: is_crc_byte = 8'b00111100;
                8'b00100000: is_crc_byte = 8'b00011110;
                8'b00010000: is_crc_byte = 8'b00001111;
                8'b00001000: is_crc_byte = 8'b00000111;
                8'b00000100: is_crc_byte = 8'b00000011;
                8'b00000010: is_crc_byte = 8'b00000001;
                default:     is_crc_byte = 0;
            endcase
        end
    end
    

    logic [7:0] byte_crc_calc;
    always_comb begin
    for (int i = 0; i < BYTE_LANES; i = i + 1) begin: output_tkeep
        m_axis_tkeep[i] = state_q[i] == X_DATA;
        byte_crc_calc[i] = !is_crc_byte[i] & (m_axis_tkeep[i] | state_q[i] == X_ADDRESS);
    end
        m_axis_tvalid   = | m_axis_tkeep;
        m_axis_tdata    = prev_RXD;
        m_axis_tlast    = m_axis_tvalid & (!m_axis_tkeep[7] | term_detected[0]);
    end

    wire [31:0] crc;
    reg crc_check;

    reg [31:0] recv_crc;

    always_ff @(posedge i_clk or posedge i_arst)
    if (i_arst)
        recv_crc <= 0;
    else if (| term_detected)
        case (term_detected)
            8'b00000001: recv_crc <= {prev_RXD[63:32]};
            8'b00000010: recv_crc <= {i_RXD[7:0], prev_RXD[63:40]};
            8'b00000100: recv_crc <= {i_RXD[15:0], prev_RXD[63:48]};
            8'b00001000: recv_crc <= {i_RXD[23:0], prev_RXD[63:56]};
            8'b00010000: recv_crc <= i_RXD[31:0];
            8'b00100000: recv_crc <= i_RXD[39:8];
            8'b01000000: recv_crc <= i_RXD[47:16];
            8'b10000000: recv_crc <= i_RXD[55:24];
            default:     recv_crc <= 0; // This would be an invalid frame
        endcase


    crc_calc crc_calc_inst (
        .i_clk(i_clk),
        .i_arst(| start_detected),
        .i_data(prev_RXD),
        .i_keep(byte_crc_calc),
        .i_valid(1),
        .o_crc(crc)
    );

    assign crc_check = crc == recv_crc;
    assign m_axis_tinvalid = !m_axis_tvalid & ~crc_check;
endmodule
