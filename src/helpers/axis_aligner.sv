module axis_aligner #(
    parameter BYTE_LANES = 8
) (
    input wire i_clk,
    input wire i_arst,

    input  wire  [(BYTE_LANES * 8) - 1 : 0] s_axis_tdata,
    input  wire  [BYTE_LANES - 1 : 0]       s_axis_tkeep,
    input  wire                             s_axis_tvalid,
    input  wire                             s_axis_tlast,
    output logic                            s_axis_tready,

    output logic [(BYTE_LANES * 8) - 1 : 0] m_axis_tdata,
    output logic [BYTE_LANES - 1 : 0]       m_axis_tkeep,
    output logic                            m_axis_tvalid,
    output logic                            m_axis_tlast,
    input  wire                             m_axis_tready
);

    logic [(BYTE_LANES * 8) - 1 : 0] tdata_q, tdata_packed;
    logic [BYTE_LANES - 1 : 0]       tkeep_q, tkeep_packed;
    logic                            tlast_q, tlast_packed;
    logic                            tvalid_q, tvalid_packed;

    logic [$clog2(BYTE_LANES) - 1 : 0] shift_count;

    typedef enum logic [1:0] {
        IDLE,
        PASSTHROUGH,
        SHIFT,
        SHIFT_LAST
    } state_t;

    state_t state, next_state;

    always_comb begin
        case (state)
            IDLE:        next_state = s_axis_tvalid ? (s_axis_tkeep[0] ? PASSTHROUGH : SHIFT) : IDLE;
            PASSTHROUGH: next_state = s_axis_tlast ? IDLE : PASSTHROUGH;
            SHIFT:       next_state = s_axis_tlast ? (!s_axis_tkeep[shift_count] ? IDLE : SHIFT_LAST) : SHIFT;
            SHIFT_LAST:  next_state = IDLE;
            default:     next_state = IDLE;
        endcase
    end

    logic master_read;
    assign master_read = m_axis_tvalid & m_axis_tready;

    logic slave_read;
    assign slave_read = s_axis_tvalid & s_axis_tready;

    always_ff @(posedge i_clk or posedge i_arst)
    if (i_arst)
        state <= IDLE;
    else
        state <= (master_read | slave_read) ? next_state : state;

    always_ff @(posedge i_clk) begin
        if (s_axis_tvalid & s_axis_tready) begin
            tdata_q  <= s_axis_tdata;
            tkeep_q  <= s_axis_tkeep;
            tlast_q  <= s_axis_tlast;
            tvalid_q <= s_axis_tvalid;
        end
    end

    always_comb begin
        if ((state == IDLE & next_state == PASSTHROUGH) | state == PASSTHROUGH) begin
            m_axis_tdata  = s_axis_tdata;
            m_axis_tkeep  = s_axis_tkeep;
            m_axis_tvalid = s_axis_tvalid;
            m_axis_tlast  = s_axis_tlast;
            s_axis_tready = m_axis_tready;
        end
        else if (state == SHIFT) begin
            m_axis_tdata  = tdata_packed;
            m_axis_tkeep  = tkeep_packed;
            m_axis_tvalid = tvalid_packed;
            m_axis_tlast  = tlast_packed;
            s_axis_tready = m_axis_tready | !tvalid_q;
        end
        else if (state == SHIFT_LAST) begin
            m_axis_tdata  = tdata_packed;
            m_axis_tkeep  = tkeep_packed;
            m_axis_tvalid = tvalid_packed;
            m_axis_tlast  = tlast_packed;
            s_axis_tready = 0;
        end
        else begin
            m_axis_tdata  = 0;
            m_axis_tkeep  = 0;
            m_axis_tvalid = 0;
            m_axis_tlast  = 0;
            s_axis_tready = 1;
        end
    end

    double_word_packer #(
        .BYTE_LANES(BYTE_LANES)
    ) data_packer (
        tdata_q,
        s_axis_tdata,
        shift_count,

        tdata_packed
    );

    double_word_packer #(
        .BYTE_LANES(BYTE_LANES),
        .BYTE_WIDTH(1)
    ) keep_packer (
        tkeep_q,
        state == SHIFT_LAST ? 0 : s_axis_tkeep,
        shift_count,

        tkeep_packed
    );

    logic [$clog2(BYTE_LANES) - 1 : 0] shift_count_w;
    logic reached_end;
    always_comb begin
        reached_end = 0;
        shift_count_w = 0;
        for (int i = 0; i < BYTE_LANES; i = i + 1) begin
            if (!reached_end & !s_axis_tkeep[i]) begin
                shift_count_w = $clog2(BYTE_LANES)'($unsigned(i + 1));
            end
            if (s_axis_tkeep[i]) begin
                reached_end = 1;
            end
        end
    end

    always_ff @(posedge i_clk or posedge i_arst)
    if (i_arst)
        shift_count <= 0;
    else if (state == IDLE & next_state == SHIFT)
        shift_count <= shift_count_w;

    always_comb begin
        tvalid_packed = tvalid_q & (s_axis_tvalid | tlast_q);
        tlast_packed  = tlast_q | (s_axis_tlast & !s_axis_tkeep[shift_count]);
    end

endmodule


module double_word_packer #(
    parameter BYTE_LANES = 8,
    parameter BYTE_WIDTH = 8
) (
    input wire [BYTE_LANES * BYTE_WIDTH - 1:0] word_low,
    input wire [BYTE_LANES * BYTE_WIDTH - 1:0] word_high,
    input wire [$clog2(BYTE_LANES)-1:0] shift_count,

    output logic [BYTE_LANES * BYTE_WIDTH - 1:0] word_pack
);

    parameter BITS = BYTE_LANES * BYTE_WIDTH;

    wire [$clog2(BITS)-1:0] BYTE_LANES_short = $clog2(BITS)'(BYTE_LANES);
    wire [$clog2(BITS)-1:0] BYTE_WIDTH_short = $clog2(BITS)'(BYTE_WIDTH);

    assign word_pack = (word_low >> ($clog2(BITS)'(shift_count) * BYTE_WIDTH_short)) | (word_high << ((BYTE_LANES_short - $clog2(BITS)'(shift_count)) * BYTE_WIDTH_short));

endmodule
