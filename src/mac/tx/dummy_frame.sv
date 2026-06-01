module dummy_frame #(
    parameter COUNT_BITS=32
) (
    input wire i_clk,
    input wire i_arst,
    
    input  wire        i_ready,
    output wire [31:0] o_data,
    output reg  [3:0]  o_valid,
    output wire        o_last
);

    reg [31:0] packet [0:7];

    initial begin
        packet[0]  = 32'h01000608;
        packet[1]  = 32'h04060008;
        packet[2]  = 32'h01C00100;
        packet[3]  = 32'hCB35F222;
        packet[4]  = 32'hCD01000A;
        packet[5]  = 32'h00000000;
        packet[6]  = 32'h01010000;
        packet[7]  = 32'h00000101;
    end

    reg [2:0] pointer = 0;

    reg [COUNT_BITS - 1:0] counter = 0;

    always_ff @(posedge i_clk or posedge i_arst)
    if (i_arst)
        {pointer, counter} <= 0;
    else begin
        if (!o_last && i_ready && &o_valid)
            pointer <= pointer + 1;
        if (o_last)
            {counter, pointer} <= 0;
        if (~(&counter))
            counter <= counter + 1;
    end
    
    always_ff @(posedge i_clk or posedge i_arst)
    if (i_arst)
        o_valid <= 0;
    else begin
        o_valid <= {4{&counter}};
    end
    assign o_data = packet[pointer];
    assign o_last = pointer == 7;

endmodule