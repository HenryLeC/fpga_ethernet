module crc_calc (
    input  wire        i_clk,
    input  wire        i_arst,
    input  wire [63:0] i_data,
    input  wire [ 7:0] i_keep,
    input  wire        i_valid,
    output wire [31:0] o_crc
);
    logic [31:0] current_crc = 32'hFFFFFFFF;

    logic [31:0] crc_next_low;
    logic [31:0] crc_next_high;

    always_ff @(posedge i_clk or posedge i_arst)
    if (i_arst)
        current_crc <= 32'hFFFFFFFF;
    else
        current_crc <= crc_next_high;

    crc_calc_half crc_calc_low_inst (
        .i_clk(i_clk),
        .i_arst(i_arst),
        
        .i_crc(current_crc),
        .i_data(i_data[31:0]),
        .i_keep(i_keep[3:0]),
        .i_valid(i_valid),
        .o_crc(crc_next_low)
    );
    
    crc_calc_half crc_calc_high_inst (
        .i_clk(i_clk),
        .i_arst(i_arst),
        
        .i_crc(crc_next_low),
        .i_data(i_data[63:32]),
        .i_keep(i_keep[7:4]),
        .i_valid(i_valid),
        .o_crc(crc_next_high)
    );



    assign o_crc = ~current_crc;

endmodule

module crc_calc_half (
    input  wire        i_clk,
    input  wire        i_arst,
    input  wire [31:0] i_crc,
    input  wire [31:0] i_data,
    input  wire [ 3:0] i_keep,
    input  wire        i_valid,
    output logic [31:0] o_crc
);
    crc_ila crc_ila_inst (
        .clk(i_clk),
        .probe0(i_arst),
        .probe1(i_data),
        .probe2(i_keep),
        .probe3(i_valid),
        .probe4(o_crc)
    );

    reg [31:0] lookup_0 [0:255];
    reg [31:0] lookup_1 [0:255];
    reg [31:0] lookup_2 [0:255];
    reg [31:0] lookup_3 [0:255];

    initial begin
        $readmemh("crc_lookup_0.hex", lookup_0);
        $readmemh("crc_lookup_1.hex", lookup_1);
        $readmemh("crc_lookup_2.hex", lookup_2);
        $readmemh("crc_lookup_3.hex", lookup_3);
    end


    logic [31:0] field_one;

    always_comb begin
        field_one = i_data ^ i_crc;
        case (i_keep)
        4'b0001: o_crc = (i_crc >> 8 ) ^ lookup_0[field_one[7:0]];
        4'b0011: o_crc = (i_crc >> 16) ^ lookup_1[field_one[7:0]] ^ lookup_0[field_one[15:8]];
        4'b0111: o_crc = (i_crc >> 24) ^ lookup_2[field_one[7:0]] ^ lookup_1[field_one[15:8]] ^ lookup_0[field_one[23:16]];
        4'b1111: o_crc = lookup_3[field_one[7:0]] ^ lookup_2[field_one[15:8]] ^ lookup_1[field_one[23:16]] ^ lookup_0[field_one[31:24]];
        default: o_crc = i_crc;
        endcase
    end

endmodule
