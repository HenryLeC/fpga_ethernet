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

    output wire [7:0] pcie_tx_p,
    output wire [7:0] pcie_tx_n,
    input  wire [7:0] pcie_rx_p,
    input  wire [7:0] pcie_rx_n,

    input  wire       pcie_refclk_p,
    input  wire       pcie_refclk_n,

    input  wire       pcie_reset_n,

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

    wire [31:0] udp_axis_tdata;
    wire [3:0] udp_axis_tkeep;
    wire [15:0] udp_axis_tlength;
    wire udp_axis_tvalid;
    wire udp_axis_tready = 1;
    wire udp_axis_tlast;

    mac mac_inst(
        .i_txclk(tx_clk),
        .i_arst(rst_txsync),
        .o_TXD(TXD),
        .o_TXC(TXC),
        .i_rxclk(rx_clk),
        .i_RXD(RXD),
        .i_RXC(RXC)

        // .udp_data_tdata(udp_axis_tdata),
        // .udp_data_tkeep(udp_axis_tkeep),
        // .udp_data_tvalid(udp_axis_tvalid),
        // .udp_data_tready(udp_axis_tready),
        // .udp_data_tlast(udp_axis_tlast),
        // .udp_data_tlength(udp_axis_tlength)
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

    wire pcie_axi_clk, pcie_axis_arstn, pcie_reset_n_c;

    wire sys_clk, sys_clk_gt;

    IBUFDS_GTE4 #(
        .REFCLK_HROW_CK_SEL(2'b00)
    ) refclk_ibuf (
        .I(pcie_refclk_p),
        .IB(pcie_refclk_n),
        .CEB(1'b0),
        .O(sys_clk_gt),
        .ODIV2(sys_clk)
    );
    // Reset buffer
    IBUF sys_reset_n_ibuf (
        .I(pcie_reset_n),
        .O(pcie_reset_n_c)
    );

    wire [255:0] s_axis_c2h_tdata_0;
    wire         s_axis_c2h_tlast_0;
    wire         s_axis_c2h_tvalid_0;
    wire         s_axis_c2h_tready_0;
    wire [ 31:0] s_axis_c2h_tkeep_0;

    wire [255:0] m_axis_h2c_tdata_0;
    wire         m_axis_h2c_tlast_0;
    wire         m_axis_h2c_tvalid_0;
    wire         m_axis_h2c_tready_0;
    wire [ 31:0] m_axis_h2c_tkeep_0;

    assign s_axis_c2h_tdata_0 = m_axis_h2c_tdata_0;
    assign s_axis_c2h_tvalid_0 = m_axis_h2c_tvalid_0;
    assign s_axis_c2h_tkeep_0 = m_axis_h2c_tkeep_0;
    assign s_axis_c2h_tlast_0 = m_axis_h2c_tlast_0;
    assign m_axis_h2c_tready_0 = s_axis_c2h_tready_0;


    xdma pcie_dma_inst (
        .sys_clk(sys_clk),                                    // input wire sys_clk
        .sys_clk_gt(sys_clk_gt),                              // input wire sys_clk_gt
        .sys_rst_n(pcie_reset_n_c),                                // input wire sys_rst_n

        .user_lnk_up(),                            // output wire user_lnk_up

        .pci_exp_txp(pcie_tx_p),                            // output wire [7 : 0] pci_exp_txp
        .pci_exp_txn(pcie_tx_n),                            // output wire [7 : 0] pci_exp_txn
        .pci_exp_rxp(pcie_rx_p),                            // input wire [7 : 0] pci_exp_rxp
        .pci_exp_rxn(pcie_rx_n),                            // input wire [7 : 0] pci_exp_rxn

        .axi_aclk(pcie_axi_clk),                                  // output wire axi_aclk
        .axi_aresetn(pcie_axis_arstn),                            // output wire axi_aresetn

        .usr_irq_req(1'b0),                            // input wire [0 : 0] usr_irq_req
        .usr_irq_ack(),                            // output wire [0 : 0] usr_irq_ack
        .msi_enable(),                              // output wire msi_enable
        .msi_vector_width(),                  // output wire [2 : 0] msi_vector_width
        
        .cfg_mgmt_addr(19'b0),                        // input wire [18 : 0] cfg_mgmt_addr
        .cfg_mgmt_write(1'b0),                      // input wire cfg_mgmt_write
        .cfg_mgmt_write_data(32'b0),            // input wire [31 : 0] cfg_mgmt_write_data
        .cfg_mgmt_byte_enable(4'b0),          // input wire [3 : 0] cfg_mgmt_byte_enable
        .cfg_mgmt_read(1'b0),                        // input wire cfg_mgmt_read
        .cfg_mgmt_read_data(),              // output wire [31 : 0] cfg_mgmt_read_data
        .cfg_mgmt_read_write_done(),  // output wire cfg_mgmt_read_write_done
        
        .s_axis_c2h_tdata_0(s_axis_c2h_tdata_0),              // input wire [255 : 0] s_axis_c2h_tdata_0
        .s_axis_c2h_tlast_0(s_axis_c2h_tlast_0),              // input wire s_axis_c2h_tlast_0
        .s_axis_c2h_tvalid_0(s_axis_c2h_tvalid_0),            // input wire s_axis_c2h_tvalid_0
        .s_axis_c2h_tready_0(s_axis_c2h_tready_0),            // output wire s_axis_c2h_tready_0
        .s_axis_c2h_tkeep_0(s_axis_c2h_tkeep_0),              // input wire [31 : 0] s_axis_c2h_tkeep_0
        
        .m_axis_h2c_tdata_0(m_axis_h2c_tdata_0),              // output wire [255 : 0] m_axis_h2c_tdata_0
        .m_axis_h2c_tlast_0(m_axis_h2c_tlast_0),              // output wire m_axis_h2c_tlast_0
        .m_axis_h2c_tvalid_0(m_axis_h2c_tvalid_0),            // output wire m_axis_h2c_tvalid_0
        .m_axis_h2c_tready_0(m_axis_h2c_tready_0),            // input wire m_axis_h2c_tready_0
        .m_axis_h2c_tkeep_0(m_axis_h2c_tkeep_0)              // output wire [31 : 0] m_axis_h2c_tkeep_0
    );

    // pcie_to_data_stream pcie_conv_inst (
    //     .pcie_axis_clk(pcie_axi_clk),
    //     .pcie_axis_arstn(pcie_axis_arstn),
        
    //     .pcie_axis_tdata(m_axis_h2c_tdata_0),
    //     .pcie_axis_tvalid(m_axis_h2c_tvalid_0),
    //     .pcie_axis_tkeep(m_axis_h2c_tkeep_0),
    //     .pcie_axis_tlast(m_axis_h2c_tlast_0),
    //     .pcie_axis_tready(m_axis_h2c_tready_0),

    //     .eth_axis_clk(tx_clk),
    //     .eth_axis_arstn(~rst_txsync),
        
    //     .eth_axis_tdata(udp_axis_tdata),
    //     .eth_axis_tvalid(udp_axis_tvalid),
    //     .eth_axis_tkeep(udp_axis_tkeep),
    //     .eth_axis_tlast(udp_axis_tlast),
    //     .eth_axis_tready(udp_axis_tready),
    //     .data_length(udp_axis_tlength)
    // );

endmodule
