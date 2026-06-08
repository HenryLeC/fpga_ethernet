module checksum_calc #(
    parameter [7:0] TTL = 8'h40
) (
    input  wire i_clk,
    input  wire i_arst,

    input  wire  [15:0] packet_length,
    input  wire  [15:0] identification,
    input  wire  [ 7:0] protocol,
    input  wire  [31:0] source_address,
    input  wire  [31:0] destination_address,
    input  wire         data_valid,

    output logic [15:0] checksum,
    output wire         checksum_valid
);

    assign checksum = ~curr_checksum;

    // We have 3 clock cycles from data begin valid to generate the checksum
    // We also have 9 blocks we need to add for the checksum.
    wire [15:0] intermediate_sum_1, intermediate_sum_2;

    wire [15:0] sum_out;
    logic [15:0] block_1, block_2, block_3;
    
    reg [15:0] curr_checksum;
    ones_complement_adder adder_1 (
        .a(curr_checksum),
        .b(block_1),
        .sum(intermediate_sum_1)
    );

    ones_complement_adder adder_2 (
        .a(block_2),
        .b(block_3),
        .sum(intermediate_sum_2)
    );
    ones_complement_adder adder_3 (
        .a(intermediate_sum_1),
        .b(intermediate_sum_2),
        .sum(sum_out)
    );

    logic [1:0] cycle_count;

    initial cycle_count = 0;
    always_ff @(posedge i_clk or posedge i_arst)
    if (i_arst)
        cycle_count <= 0;
    else if (cycle_count == 0)
        cycle_count <= data_valid ? 1 : 0;
    else if (cycle_count == 3)
        cycle_count <= cycle_count;
    else
        cycle_count <= cycle_count + 1;

    initial curr_checksum = 0;
    always_ff @(posedge i_clk or posedge i_arst)
    if (i_arst)
        curr_checksum <= 0;
    else if (cycle_count < 3 & data_valid)
        curr_checksum <= sum_out;

    always_comb
    case (cycle_count)
    2'd0: begin
        block_1 = 16'h0045; // Version, IHL, DSCP, ECN
        block_2 = {packet_length[7:0], packet_length[15:8]}; // Total Length
        block_3 = {identification[7:0], identification[15:8]}; // Identification
    end
    2'd1: begin
        block_1 = 16'h0; // Flags, Fragment Offset
        block_2 = {protocol, TTL}; // TTL, Protocol
        block_3 = {source_address[23:16], source_address[31:24]}; // Source Address [31:16]
    end 
    2'd2: begin
        block_1 = {source_address[7:0], source_address[15:8]};
        block_2 = {destination_address[23:16], destination_address[31:24]};
        block_3 = {destination_address[7:0], destination_address[15:8]};
    end
    default: {block_1, block_2, block_3} = {3{16'h0}};
    endcase

    assign checksum_valid = cycle_count == 2'd3;
endmodule

module ones_complement_adder #(parameter N=16) (
    input  wire [N-1:0] a,
    input  wire [N-1:0] b,
    output wire [N-1:0] sum
);
    wire [N:0] full_sum;
    assign full_sum = a + b;

    assign sum = full_sum[N-1:0] + {{(N-1){1'b0}}, full_sum[N]};

endmodule