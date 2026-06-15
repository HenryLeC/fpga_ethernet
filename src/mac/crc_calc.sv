module crc_calc (
    input  wire        i_clk,
    input  wire        i_arst,
    input  wire [31:0] i_data,
    input  wire [ 3:0] i_keep,
    input  wire        i_valid,
    output wire [31:0] o_crc
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


    reg [31:0] crc_next;
    reg [31:0] field_one;

    reg [31:0] current_crc;


    initial current_crc = 32'hFFFFFFFF;
    always_ff @(posedge i_clk or posedge i_arst)
    if (i_arst)
        current_crc <= 32'hFFFFFFFF;
    else
        current_crc <= crc_next;


    always_comb begin
        field_one = i_data ^ current_crc;
        case (i_keep)
        4'b0001: crc_next = (current_crc >> 8 ) ^ lookup_0[field_one[7:0]];
        4'b0011: crc_next = (current_crc >> 16) ^ lookup_1[field_one[7:0]] ^ lookup_0[field_one[15:8]];
        4'b0111: crc_next = (current_crc >> 24) ^ lookup_2[field_one[7:0]] ^ lookup_1[field_one[15:8]] ^ lookup_0[field_one[23:16]];
        4'b1111: crc_next = lookup_3[field_one[7:0]] ^ lookup_2[field_one[15:8]] ^ lookup_1[field_one[23:16]] ^ lookup_0[field_one[31:24]];
        default: crc_next = current_crc;
        endcase
    end

    assign o_crc = ~current_crc;

endmodule