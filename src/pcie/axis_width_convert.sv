`default_nettype none
module axis_width_convert(
    input wire axis_clk,
    input wire axis_arstn,

    input  wire [255:0] s_axis_tdata,
    input  wire         s_axis_tvalid,
    input  wire [ 31:0] s_axis_tkeep,
    input  wire         s_axis_tlast,
    output wire         s_axis_tready,

    output logic [31:0] m_axis_tdata,
    output wire         m_axis_tvalid,
    output logic [ 3:0] m_axis_tkeep,
    output wire         m_axis_tlast,
    input  wire         m_axis_tready
);

    reg [255:0] stored_data;
    reg         stored_valid;
    reg [ 31:0] stored_keep;
    reg         stored_last;


    reg [2:0] position;

    initial {stored_data, stored_valid, stored_keep, stored_last} = 0;
    always_ff @(posedge axis_clk or negedge axis_arstn)
    if (!axis_arstn)
        {stored_data, stored_valid, stored_keep, stored_last} <= 0;
    else if (s_axis_tready)
        {stored_data, stored_valid, stored_keep, stored_last} <= {s_axis_tdata, s_axis_tvalid, s_axis_tkeep, s_axis_tlast};

    
    always_ff @(posedge axis_clk or negedge axis_arstn)
    if (!axis_arstn)
        position <= 0;
    else if (m_axis_tvalid & m_axis_tready)
        position <= position + 1;

    logic next_dword_low_keep;
    assign m_axis_tvalid = stored_valid;
    assign m_axis_tlast = stored_last & (&position | ~(&m_axis_tkeep) | ~next_dword_low_keep);

    always_comb
    case (position)
    3'd0: {m_axis_tdata, m_axis_tkeep} = {stored_data[31:0], stored_keep[3:0]};
    3'd1: {m_axis_tdata, m_axis_tkeep} = {stored_data[63:32], stored_keep[7:4]};
    3'd2: {m_axis_tdata, m_axis_tkeep} = {stored_data[95:64], stored_keep[11:8]};
    3'd3: {m_axis_tdata, m_axis_tkeep} = {stored_data[127:96], stored_keep[15:12]};
    3'd4: {m_axis_tdata, m_axis_tkeep} = {stored_data[159:128], stored_keep[19:16]};
    3'd5: {m_axis_tdata, m_axis_tkeep} = {stored_data[191:160], stored_keep[23:20]};
    3'd6: {m_axis_tdata, m_axis_tkeep} = {stored_data[223:192], stored_keep[27:24]};
    3'd7: {m_axis_tdata, m_axis_tkeep} = {stored_data[255:224], stored_keep[31:28]};
    endcase


    always_comb
    case (position)
    3'd0: next_dword_low_keep = stored_keep[(0 * 4) + 4];
    3'd1: next_dword_low_keep = stored_keep[(1 * 4) + 4];
    3'd2: next_dword_low_keep = stored_keep[(2 * 4) + 4];
    3'd3: next_dword_low_keep = stored_keep[(3 * 4) + 4];
    3'd4: next_dword_low_keep = stored_keep[(4 * 4) + 4];
    3'd5: next_dword_low_keep = stored_keep[(5 * 4) + 4];
    3'd6: next_dword_low_keep = stored_keep[(6 * 4) + 4];
    3'd7: next_dword_low_keep = 0;
    endcase

    assign s_axis_tready = !stored_valid | (&position & m_axis_tready) | m_axis_tlast;
endmodule