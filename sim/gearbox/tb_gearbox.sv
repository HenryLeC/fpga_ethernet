`timescale 1ns/1ps
module TB_gearbox();
    reg clk, arst_n;
    wire [3:0] led;
    gearbox DUT(clk, arst_n, led);

    always #1
        clk <= ~clk;

    initial begin
        $dumpfile("gearbox.vcd");
        $dumpvars(0, DUT);
        clk <= 0;
        arst_n <= 0;
        #10;
        arst_n <= 1;
    end

    always #1 begin
        if (led == 4'h1) begin
            $finish();
        end
    end

endmodule