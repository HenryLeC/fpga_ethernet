module gearbox #(
    parameter COUNT_WIDTH = 12
) (
    input wire clk,
    input wire arst_n,
    output reg [3:0] led
);
    reg [COUNT_WIDTH-1:0] counter;


    always_ff @(posedge clk or negedge arst_n) begin
        if (!arst_n) begin
            counter <= 1'b0;
        end else begin
            counter <= counter + 1'b1;
        end
    end

    always_comb begin : led_out
        led = counter[COUNT_WIDTH-1:COUNT_WIDTH-5];
    end
endmodule