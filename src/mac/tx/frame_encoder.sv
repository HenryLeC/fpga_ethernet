`default_nettype none
module frame_encoder (
    input  wire i_clk,
    input  wire i_arst,

    input  wire [31:0] i_clientdata,
    input  wire [ 3:0] i_clientdata_keep,
    input  wire        i_clientdata_valid,
    input  wire        i_last,
    output wire         o_ready,

    output logic [3:0]  TXC,
    output logic [31:0] TXD
);

    wire [31:0] xgmii_data;
    wire [ 3:0] xgmii_control;
    wire [ 3:0] xgmii_keep;

    wire [31:0] xgmii_data_shifted;
    wire [ 3:0] xgmii_control_shifted;
    wire [ 3:0] xgmii_keep_shifted;

    frame_builder frame_builder_inst (
        .i_clk(i_clk),
        .i_arst(i_arst),

        .i_clientdata(i_clientdata),
        .i_clientdata_keep(i_clientdata_keep),
        .i_clientdata_valid(i_clientdata_valid),
        .i_last(i_last),
        .o_ready(o_ready),

        .xgmii_data(xgmii_data),
        .xgmii_control(xgmii_control),
        .xgmii_keep(xgmii_keep)
    );

    double_word_packer #(
        .BYTE_LANES(4),
        .BYTE_WIDTH(8)
    ) data_packer (
        .word_low(xgmii_next_data[0]),
        .word_high(xgmii_next_data[1]),
        .shift_count(shift_count),
        
        .word_pack(TXD)
    );
    
    double_word_packer #(
        .BYTE_LANES(4),
        .BYTE_WIDTH(1)
    ) control_packer (
        .word_low(xgmii_next_control[0]),
        .word_high(xgmii_next_control[1]),
        .shift_count(shift_count),
        
        .word_pack(TXC)
    );

    shift_out_used #(
        .BYTE_LANES(4),
        .BYTE_WIDTH(8),
        .UPPER_BYTES(8'h07)
    ) data_shift_out (
        .word(xgmii_next_data[1]),
        .shift_count(shift_count),

        .out(xgmii_data_shifted)
    );
    
    shift_out_used #(
        .BYTE_LANES(4),
        .BYTE_WIDTH(1),
        .UPPER_BYTES(1'd1)
    ) control_shift_out (
        .word(xgmii_next_control[1]),
        .shift_count(shift_count),

        .out(xgmii_control_shifted)
    );
    
    shift_out_used #(
        .BYTE_LANES(4),
        .BYTE_WIDTH(1),
        .UPPER_BYTES(1'd0)
    ) keep_shift_out (
        .word(xgmii_next_keep[1]),
        .shift_count(shift_count),

        .out(xgmii_keep_shifted)
    );

    logic [1:0] shift_count;

    always_ff @(posedge i_clk)
    case (xgmii_keep_shifted)
    4'b0111: shift_count <= shift_count > 1 ? shift_count : 1;
    4'b0011: shift_count <= shift_count > 2 ? shift_count : 2;
    4'b0001: shift_count <= 3;
    default: shift_count <= 0;
    endcase


    logic [31:0] xgmii_next_data [0:1];
    logic [ 3:0] xgmii_next_control [0:1];
    logic [ 3:0] xgmii_next_keep [0:1];

    logic       control [0:3];
    

    always_ff @(posedge i_clk) begin
        xgmii_next_data[0] <= xgmii_data_shifted;
        xgmii_next_control[0] <= xgmii_control_shifted;
        xgmii_next_keep[0] <= xgmii_keep_shifted;
    end
    always_comb begin
        xgmii_next_data[1] = xgmii_data;
        xgmii_next_control[1] = xgmii_control;
        xgmii_next_keep[1] = xgmii_keep;
    end
endmodule

module double_word_packer #(
    parameter BYTE_LANES = 4,
    parameter BYTE_WIDTH = 8
) (
    input wire [BYTE_LANES * BYTE_WIDTH - 1:0] word_low,
    input wire [BYTE_LANES * BYTE_WIDTH - 1:0] word_high,
    input wire [$clog2(BYTE_LANES)-1:0] shift_count,

    output logic [BYTE_LANES * BYTE_WIDTH - 1:0] word_pack
);

    wire [$clog2(BYTE_LANES):0] BYTE_LANES_short = BYTE_LANES[$clog2(BYTE_LANES):0];

    wire [BYTE_LANES * BYTE_WIDTH - 1:0] low_mask, high_mask;

    assign low_mask  = {(BYTE_LANES * BYTE_WIDTH){1'b1}} >> (shift_count * BYTE_WIDTH);
    assign high_mask = ~low_mask;

    assign word_pack = (word_low & low_mask) | (word_high << ((BYTE_LANES_short - {2'd0, shift_count}) * BYTE_WIDTH));

endmodule

module shift_out_used #(
    parameter BYTE_LANES = 4,
    parameter BYTE_WIDTH = 8,
    parameter [BYTE_WIDTH-1:0] UPPER_BYTES = 0
) (
    input wire [BYTE_LANES * BYTE_WIDTH -1:0] word,
    input wire [$clog2(BYTE_LANES)-1:0] shift_count,

    output logic [BYTE_LANES * BYTE_WIDTH -1:0] out
);
    wire [$clog2(BYTE_LANES):0] BYTE_LANES_short = BYTE_LANES[$clog2(BYTE_LANES):0];
    
    wire [BYTE_LANES * BYTE_WIDTH -1:0] top, low_mask, high_mask;

    
    assign top  = {BYTE_LANES{UPPER_BYTES}} << ((BYTE_LANES_short - {2'd0, shift_count}) * BYTE_WIDTH);
    
    assign out = top | (word >> (shift_count * BYTE_WIDTH));

endmodule