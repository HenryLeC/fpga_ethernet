module scrambler_loop #(
    parameter bit [57:0] INITIAL_STATE = 58'hFFFFFFFFFFFFFFF
) (
    input wire i_clk,

    input wire [63:0] data_in,

    output wire [63:0] data_out
);

    reg [57:0] scrambler_state = INITIAL_STATE;
    wire [57:0] scrambler_state_out;
    
    reg [57:0] descrambler_state = INITIAL_STATE;
    wire [57:0] descrambler_state_out;

    always_ff @(posedge i_clk) begin
        scrambler_state <= scrambler_state_out;
        descrambler_state <= descrambler_state_out;
    end

    wire [63:0] scrambled;

    scrambler_parallel scrambler_inst (
        .data_in(data_in),
        .state_in(scrambler_state),

        .data_out(scrambled),
        .state_out(scrambler_state_out)
    );


    descrambler_parallel descrambler_inst (
        .data_in(scrambled),
        .state_in(descrambler_state),

        .data_out(data_out),
        .state_out(descrambler_state_out)
    );

endmodule