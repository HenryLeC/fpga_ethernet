`timescale 1ps/1ps
`default_nettype none
module top (
    input wire clk_100mhz_p,
    input wire clk_100mhz_n,

    input wire sfp_mgt_refclk_p,
    input wire sfp_mgt_refclk_n,

    input wire [1:0] sfp_rx_p,
    input wire [1:0] sfp_rx_n,

    output wire [1:0] sfp_tx_p,
    output wire [1:0] sfp_tx_n,

    inout wire [1:0] sfp_i2c_scl,
    inout wire [1:0] sfp_i2c_sda,
    input wire [1:0] sfp_npres,

    output wire [3:0] led,
    output wire [1:0] sfp_led
);
    wire        clk_ibuf, clk_100mhz;
    reg  [28:0] ctr_q = 29'd0;
    reg         unused_ctr_q = 1'b0;
    reg  [29:0] powerup_reset_q = 30'hffffffff;

    wire sfp0_sda_i;
    wire sfp0_sda_o;
    wire sfp0_sda_t;
    wire sfp0_scl_i;
    wire sfp0_scl_o;
    wire sfp0_scl_t;

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
        .O(clk_100mhz)
    );

    IOBUF sfp_1_sda(
        .O(sfp0_sda_i),
        .I(sfp0_sda_o),
        .IO(sfp_i2c_sda[0]),
        .T(sfp0_sda_t)
    );

    IOBUF sfp_1_scl(
        .O(sfp0_scl_i),
        .I(sfp0_scl_o),
        .IO(sfp_i2c_scl[0]),
        .T(sfp0_scl_t)
    );

    always @(posedge clk_100mhz) begin
        if (sfp_npres[0]) begin
            powerup_reset_q <= 30'hffffffff;
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
        .clock                  (clk_100mhz),
        .reset_n                (~(|powerup_reset_q)),
        .enable                 (1'b1),
        .read_write             (1'b1),
        .mosi_data              (8'd0),
        .register_address       (8'd20),
        .device_address         (7'h50),
        .divider                (16'd200),

        .miso_data              (sfp0_serial_number),
        .busy                   (sfp0_busy),

        .sda_i                  (sfp0_sda_i),
        .sda_o                  (sfp0_sda_o),
        .sda_t                  (sfp0_sda_t),
        .scl_i                  (sfp0_scl_i),
        .scl_o                  (sfp0_scl_o),
        .scl_t                  (sfp0_scl_t),

        .state_dbg              (state_dbg),
        .process_dbg            (process_dbg)
    );


    assign led = ctr_q[28:25];

    assign sfp_led[1] = sfp_npres[1];
    assign sfp_led[0] = |powerup_reset_q;

    wire        rx_clk,    tx_clk;
    wire [1:0]  rx_header, tx_header;
    wire [31:0] rx_data,   tx_data;
    wire        rx_header_valid, tx_header_valid;

    sfp_gty gty_inst(
        .mgtrefclk0_x0y3_p(sfp_mgt_refclk_p),
        .mgtrefclk0_x0y3_n(sfp_mgt_refclk_n),

        .ch0_gtyrxn_in(sfp_rx_n[0]),
        .ch0_gtyrxp_in(sfp_rx_p[0]),
        
        .ch0_gtytxn_out(sfp_tx_n[0]),
        .ch0_gtytxp_out(sfp_tx_p[0]),

        .hb_gtwiz_reset_clk_freerun_in(clk_100mhz),
        .hb_gtwiz_reset_all_in(|powerup_reset_q),

        .tx_clk(tx_clk),
        .tx_header(tx_header),
        .tx_data(tx_data),
        .tx_header_valid(tx_header_valid),

        .rx_clk(rx_clk),
        .rx_header(rx_header),
        .rx_data(rx_data),
        .rx_header_valid(rx_header_valid),

        .link_status(link_status),
        .gearbox_slip(gearbox_slip)
    );

    wire rst_rxsync;
    reset_synchronizer reset_synchronizer_tx_powerup_reset_q_inst(
        .clk_in(rx_clk),
        .rst_in(|powerup_reset_q),
        .rst_out(rst_rxsync)
    );
    wire rst_txsync;
    reset_synchronizer reset_synchronizer_rx_powerup_reset_q_inst(
        .clk_in(tx_clk),
        .rst_in(|powerup_reset_q),
        .rst_out(rst_txsync)
    );

    wire gearbox_slip, link_status;

    block_lock_sm block_lock_inst(
        .rst_a(rst_rxsync),
        .clk_rx(rx_clk),
        .rx_header(rx_header),
        .gearbox_slip(gearbox_slip),
        .block_lock(link_status)
    );

    mac mac_inst(
        .i_txclk(tx_clk),
        .i_arst(rst_txsync),
        .o_TXD(TXD),
        .o_TXC(TXC),
        .i_rxclk(rx_clk),
        .i_RXD(RXD),
        .i_RXC(RXC)
    );

    wire [63:0] RXD, TXD;
    wire [7:0] RXC, TXC;

    pcs_tx tx_pcs_inst (
        .clk(tx_clk),
        .arst(rst_txsync),
        
        .TXD(TXD),
        .TXC(TXC),

        .tx_data(tx_data),
        .tx_header(tx_header),
        .header_valid(tx_header_valid)
    );

    pcs_rx rx_pcs_inst(
        .clk(rx_clk),
        
        .rx_data(rx_data),
        .rx_header(rx_header),
        .header_valid(rx_header_valid),

        .RXD(RXD),
        .RXC(RXC)
    );
endmodule
