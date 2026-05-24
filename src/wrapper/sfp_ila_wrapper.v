module sfp_ila_wrapper(
    input wire clk,
    input wire sfp0_npres,
    input wire [7:0] sfp0_serial_number,
    input wire sfp0_busy,
    input wire sfp0_sda_i,
    input wire sfp0_sda_o,
    input wire sfp0_sda_t,
    input wire sfp0_scl_i,
    input wire sfp0_scl_o,
    input wire sfp0_scl_t,
    input wire [3:0] state_dbg,
    input wire [1:0] process_dbg
);

    sfp_ila sfp_ila(
        .clk(clk),
        .probe0(sfp0_npres),
        .probe1(sfp0_serial_number),
        .probe2(sfp0_busy),
        .probe3(sfp0_sda_i),
        .probe4(sfp0_sda_o),
        .probe5(sfp0_sda_t),
        .probe6(sfp0_scl_i),
        .probe7(sfp0_scl_o),
        .probe8(sfp0_scl_t),
        .probe9(state_dbg),
        .probe10(process_dbg)
    );

endmodule