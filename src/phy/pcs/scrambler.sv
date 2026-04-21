module scrambler #(
    parameter LFSR_WIDTH = 58,
    parameter LFSR_POLYNOMIAL = 58'h8000000001
) (
    input clk,
    input arst_n,
    input data,
    output reg scrambled_data
);

    reg [LFSR_WIDTH-1:0] lfsr_state;

    wire scrambled_bit = data ^ (lfsr_state[38] ^ lfsr_state[57]);

    always_ff @(posedge clk or negedge arst_n) begin
        if (!arst_n) begin
            lfsr_state <= {LFSR_WIDTH{1'b1}};
        end else begin
            scrambled_data <= scrambled_bit;
            lfsr_state <= {lfsr_state[LFSR_WIDTH-2:0], scrambled_bit};
        end;
    end

endmodule