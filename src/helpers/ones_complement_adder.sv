module ones_complement_adder #(parameter N=16) (
    input  wire [N-1:0] a,
    input  wire [N-1:0] b,
    output wire [N-1:0] sum
);
    wire [N:0] full_sum;
    assign full_sum = a + b;

    assign sum = full_sum[N-1:0] + {{(N-1){1'b0}}, full_sum[N]};

endmodule