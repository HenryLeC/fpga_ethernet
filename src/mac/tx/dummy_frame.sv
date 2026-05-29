module dummy_frame (
    input wire i_clk,
    input wire i_arst,
    
    input  wire        i_ready,
    output wire [31:0] o_data,
    output reg  [3:0]  o_valid,
    output wire        o_last
);

    reg [31:0] packet [0:11];

    reg done = 0;

    initial begin
        packet[0]  = 32'h01000608;
        packet[1]  = 32'h04060008;
        packet[2]  = 32'h01C00100;
        packet[3]  = 32'hCB35F222;
        packet[4]  = 32'hCD01000A;
        packet[5]  = 32'h00000000;
        packet[6]  = 32'h01010000;
        packet[7]  = 32'h00000101;
        packet[8]  = 32'h00000000;
        packet[9]  = 32'h00000000;
        packet[10] = 32'h00000000;
        packet[11] = 32'h00000000;
    end

    reg [3:0] pointer = 0;
    reg [15:0] startup_ctr = 0;

    always_ff @(posedge i_clk or posedge i_arst)
    if (i_arst)
        {startup_ctr, pointer, done} <= 0;
    else begin
        if (i_ready && &o_valid)
            pointer <= pointer + 1;
        if (o_last)
            done <= 1;
        startup_ctr <= startup_ctr + 1;
    end
    
    always_ff @(posedge i_clk or posedge i_arst)
    if (i_arst)
        o_valid <= 0;
    else begin
        if (startup_ctr[15] && !done)
            o_valid <= 4'hF;
        else if (done)
            o_valid <= 4'h0;
    end
    assign o_data = packet[pointer];
    assign o_last = pointer == 11;

endmodule