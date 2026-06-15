module dummy_frame_encoder #(
    parameter COUNT_BITS=32
) (
    input wire i_clk,
    input wire i_arst,

    output wire [3:0]  TXC,
    output wire [31:0] TXD
);

    wire ready, last;

    wire [31:0] data;
    wire [3:0]  keep;

    dummy_frame #(
        .COUNT_BITS(COUNT_BITS)
    ) frame_gen_inst (
        .i_clk(i_clk),
        .i_arst(i_arst),
        
        .i_ready(ready),
        .o_data(data),
        .o_valid(keep),
        .o_last(last)
    );

    frame_encoder frame_encoder_inst (
        .i_clk(i_clk),
        .i_arst(i_arst),

        .i_clientdata(data),
        .i_clientdata_valid(|keep),
        .i_clientdata_keep(keep),
        .i_last(last),
        .o_ready(ready),

        .TXC(TXC),
        .TXD(TXD)
    );

endmodule