`default_nettype none
module frame_builder (
    input  wire i_clk,
    input  wire i_arst,

    input  wire  [31:0] i_clientdata,
    input  wire  [ 3:0] i_clientdata_keep,
    input  wire         i_clientdata_valid,
    input  wire         i_last,
    output reg          o_ready,

    output logic [31:0] xgmii_data,
    output logic [ 3:0] xgmii_control,
    output logic [ 3:0] xgmii_keep
);

    wire [31:0] crc;

    crc_calc crc_calc_inst (
        .i_clk(i_clk),
        .i_arst(current_state == X_START),
        .i_data(xgmii_data),
        .i_keep(current_state == X_ADDRESS ? 4'hF : current_state == X_USER_DATA ? xgmii_keep : current_state == X_PAD ? 4'hF : 4'h0),
        .i_valid(),
        .o_crc(crc)
    );

    reg [1:0]  proc_count;
    reg [2:0]  current_state, next_state;

    reg [10:0] word_count = 0;

    localparam X_IDLE          = 3'd0;
    localparam X_START         = 3'd1;
    localparam X_ADDRESS       = 3'd2;
    localparam X_USER_DATA     = 3'd3;
    localparam X_PAD           = 3'd4;
    localparam X_FCS           = 3'd5;
    localparam X_END           = 3'd6;
    localparam X_IFG           = 3'd7;


    initial current_state = X_IDLE;
    initial proc_count = 0;
    always_ff @(posedge i_clk or posedge i_arst)
        if (i_arst) begin
            current_state <= X_IDLE;
            proc_count <= 0;
        end else begin
            current_state <= next_state;
            proc_count <= current_state != next_state ? 0 : proc_count + 1;
        end

    initial word_count = 0;
    always_ff @(posedge i_clk)
    if (current_state == X_IDLE)
        word_count <= 0;
    else if (current_state == X_USER_DATA | current_state == X_PAD)
        word_count <= word_count + 1;

    // Next state computation
    always_comb
    case (current_state)
        X_IDLE:      next_state = i_clientdata_valid == 0 ? X_IDLE : X_START;
        X_START:     next_state = proc_count == 1 ? X_ADDRESS : X_START;
        X_ADDRESS:   next_state = proc_count == 2 ? X_USER_DATA : X_ADDRESS;
        X_USER_DATA: next_state = i_last ? word_count >= 11 ? X_FCS : X_PAD : X_USER_DATA;
        X_PAD:       next_state = word_count == 11 ? X_FCS : X_PAD;
        X_FCS:       next_state = X_END;
        X_END:       next_state = X_IFG;
        X_IFG:       next_state = proc_count == 2 ? X_IDLE : X_IFG;
        default:     next_state = X_IDLE;
    endcase

    always_comb
    case (current_state)
        X_IDLE:      begin
            xgmii_data = {4{8'h07}};
            xgmii_control = 4'hF;
            xgmii_keep = 4'h0;
        end
        X_START:     begin
            xgmii_data = proc_count[0] ? 32'hD5555555 : 32'h555555FB;
            xgmii_control = proc_count[0] ? 4'h0 : 4'h1; 
            xgmii_keep = 4'hF;
        end
        X_ADDRESS:
        case (proc_count)
            0: {xgmii_keep, xgmii_control, xgmii_data} = {4'hF, 4'h0, 32'hFFFFFFFF};
            1: {xgmii_keep, xgmii_control, xgmii_data} = {4'hF, 4'h0, 32'h01C0FFFF};
            2: {xgmii_keep, xgmii_control, xgmii_data} = {4'hF, 4'h0, 32'hCB35F222};
            default: {xgmii_keep, xgmii_control, xgmii_data} = 40'd0;
        endcase
        X_USER_DATA: {xgmii_keep, xgmii_control, xgmii_data} = {i_clientdata_keep, 4'h0, i_clientdata};
        X_PAD:       {xgmii_keep, xgmii_control, xgmii_data} = {4'hF, 4'h0, 32'h0};
        X_FCS:       {xgmii_keep, xgmii_control, xgmii_data} = {4'hF, 4'h0, crc};
        X_END:       {xgmii_keep, xgmii_control, xgmii_data} = {4'h1, 4'hF, 32'h070707FD};
        X_IFG:       {xgmii_keep, xgmii_control, xgmii_data} = {4'h0, 4'hF, {4{8'h07}}};
        default:     {xgmii_keep, xgmii_control, xgmii_data} = {4'h0, 4'hF, {4{8'h07}}};
    endcase

    always_ff @(posedge i_clk) begin
        o_ready <= next_state == X_USER_DATA;
    end
endmodule