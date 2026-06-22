module scrambler #(
    parameter bit [57:0] INITIAL_STATE = 58'hFFFFFFFFFFFFFFF
) (
    input  wire  i_clk,
    input  wire  i_arst,

    input  wire  bit_in,
    output logic bit_out
);

    logic [57:0] lfsr_state;

    wire state_xor;

    xor state (state_xor, lfsr_state[38], lfsr_state[57]);
    xor in_xor (bit_out, bit_in, state_xor);

    always_ff @( posedge i_clk or posedge i_arst )
    if (i_arst)
        lfsr_state <= INITIAL_STATE;
    else
        lfsr_state <= {lfsr_state[56:0], bit_out};
endmodule