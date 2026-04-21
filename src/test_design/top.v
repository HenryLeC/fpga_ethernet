`timescale 1ps/1ps
`default_nettype none
module top (
    input wire clk_100mhz_p, 
    input wire clk_100mhz_n,

    output wire [3:0] led 
);
    wire        clk_ibuf, clk;
    reg  [28:0] ctr_q; 
    reg         unused_ctr_q;


    IBUFDS #(
        .DIFF_TERM("TRUE"),
        .IOSTANDARD("LVDS")
    ) m_ibufds (
        .I(clk_100mhz_p),
        .IB(clk_100mhz_n),
        .O(clk_ibuf)
    );

    BUFG m_bufg (
        .I(clk_ibuf),
        .O(clk)
    );

    always @(posedge clk)
        { unused_ctr_q, ctr_q } <= ctr_q + 29'b1;    
    
    assign led = ctr_q[28:25];
endmodule