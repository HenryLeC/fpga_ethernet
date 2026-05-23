`timescale 1ps/1ps
`default_nettype none
module top (
    input wire clk_100mhz_p,
    input wire clk_100mhz_n,

    inout wire [1:0] sfp_i2c_scl,
    inout wire [1:0] sfp_i2c_sda,
    input wire [1:0] sfp_npres,

    output wire [3:0] led,
    output wire [1:0] sfp_led
);
    wire        clk_ibuf, clk;
    reg  [28:0] ctr_q = 29'd0;
    reg         unused_ctr_q = 1'b0;
    reg  [31:0] powerup_reset_q = 32'hffffffff;

    wire sfp1_sda_i;
    wire sfp1_sda_o;
    wire sfp1_sda_t;
    wire sfp1_scl_i;
    wire sfp1_scl_o;
    wire sfp1_scl_t;

    (* mark_debug = "true" *) wire [1:0] sfp_npres_dbg;
    assign sfp_npres_dbg = sfp_npres;

    (* mark_debug = "true" *) wire [7:0] sfp0_serial_number;
    (* mark_debug = "true" *) wire [7:0] sfp1_serial_number;
    (* mark_debug = "true" *) wire        sfp0_done;
    (* mark_debug = "true" *) wire        sfp1_done;
    (* mark_debug = "true" *) wire        sfp0_busy;
    (* mark_debug = "true" *) wire        sfp1_busy;
    (* mark_debug = "true" *) wire        sfp0_error;
    (* mark_debug = "true" *) wire        sfp1_error;
    (* mark_debug = "true" *) wire [3:0]  sfp0_state_dbg;
    (* mark_debug = "true" *) wire [3:0]  sfp1_state_dbg;

    sfp_ila_wrapper sfp_ila (
        .clk(clk), // input wire clk
        .sfp0_npres(|powerup_reset_q), // input wire [1:0] sfp_npres
        .sfp0_serial_number(sfp1_serial_number), // input wire [127:0] sfp0_serial_number
        .sfp0_busy(sfp1_busy), // input wire [0:0] sfp0_busy
        .sfp0_sda_i(sfp1_sda_i),
        .sfp0_sda_o(sfp1_sda_o),
        .sfp0_sda_t(sfp1_sda_t),
        .sfp0_scl_i(sfp1_scl_i),
        .sfp0_scl_o(sfp1_scl_o),
        .sfp0_scl_t(sfp1_scl_t),
        .state_dbg(state_dbg),
        .process_dbg(process_dbg)
    );

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

    IOBUF sfp_1_sda(
        .O(sfp1_sda_i),
        .I(sfp1_sda_o),
        .IO(sfp_i2c_sda[1]),
        .T(sfp1_sda_t)
    );

    IOBUF sfp_1_scl(
        .O(sfp1_scl_i),
        .I(sfp1_scl_o),
        .IO(sfp_i2c_scl[1]),
        .T(sfp1_scl_t)
    );

    always @(posedge clk) begin
        if (sfp_npres[1]) begin
            powerup_reset_q <= 31'hffffffff;
        end else if (|powerup_reset_q) begin
            powerup_reset_q <= powerup_reset_q - 1;
        end
        { unused_ctr_q, ctr_q } <= ctr_q + 29'd1;
    end

    reg [7:0] transciever_type;

    wire [3:0] state_dbg;
    wire [1:0] process_dbg;

    i2c_master #(
        .NUMBER_OF_DATA_BYTES           (1),
        .NUMBER_OF_REGISTER_BYTES       (1),
        .ADDRESS_WIDTH                  (7),
        .CHECK_FOR_CLOCK_STRETCHING     (0),
        .CLOCK_STRETCHING_MAX_COUNT     ('hFF)
    )
    i2c_master_inst(
        .clock                  (clk),
        .reset_n                (~(|powerup_reset_q)),
        .enable                 (1'b1),
        .read_write             (1'b1),
        .mosi_data              (8'd0),
        .register_address       (8'd20),
        .device_address         (7'h50),
        .divider                (16'd200),

        .miso_data              (sfp1_serial_number),
        .busy                   (sfp1_busy),

        .sda_i                  (sfp1_sda_i),
        .sda_o                  (sfp1_sda_o),
        .sda_t                  (sfp1_sda_t),
        .scl_i                  (sfp1_scl_i),
        .scl_o                  (sfp1_scl_o),
        .scl_t                  (sfp1_scl_t),

        .state_dbg              (state_dbg),
        .process_dbg            (process_dbg)
    );


    assign led = ctr_q[28:25];

    assign sfp_led[0] = sfp_npres[0];
    assign sfp_led[1] = ~(|powerup_reset_q);
endmodule
