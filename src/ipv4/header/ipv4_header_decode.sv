module ipv4_header_decode #(

) (
    input wire i_clk,
    input wire i_arst,

    input  wire [63:0] s_axis_tdata,
    input  wire        s_axis_tvalid,
    output logic       s_axis_tready,
    output logic       s_axis_tlast, // This is the wrong direction for a compliant axi stream
                                     // but in this case the master does not know when the headier
                                     // is finished.
    output logic [1:0] header_tkeep, // This only lets you specify keep for the bottom 4 bytes
                                     // or the top 4 bytes but that is all we need.
                                     // Also only valid on tlast

    output logic      decode_done,
    output logic      header_valid,

    output reg [15:0] packet_length,
    output reg [15:0] identification,
    output reg [ 7:0] protocol,
    output reg [31:0] source_address,
    output reg [31:0] destination_address
);

    typedef enum logic [0:0] {
        X_RESET,
        X_READ
    } state_t;

    state_t state, next_state;

    reg invalid;
    reg [3:0] word_count;
    reg [3:0] ihl;

    reg  [15:0] checksum_check;
    wire [15:0] checksum_check_int_1, checksum_check_int_2, checksum_check_int_3;
    wire [15:0] checksum_check_next;

    logic [63:0] s_axis_tdata_prev;
    logic        s_axis_tvalid_prev, s_axis_tready_prev;
    
    logic last_dword;
    
    assign last_dword = s_axis_tvalid && |word_count && (word_count == (ihl >> 1) | ((word_count + 1) << 1) == ihl);

    ones_complement_adder checksum_adder_1 (
        s_axis_tdata_prev[15:0],
        s_axis_tdata_prev[31:16],
        checksum_check_int_1
    );
    
    ones_complement_adder checksum_adder_2 (
        s_axis_tdata_prev[47:32],
        s_axis_tdata_prev[63:48],
        checksum_check_int_2
    );

    ones_complement_adder ones_complement_adder_3 (
        checksum_check_int_1,
        last_dword & ihl[0] ? 0 : checksum_check_int_2,
        checksum_check_int_3
    );
    
    ones_complement_adder ones_complement_adder_4 (
        checksum_check,
        checksum_check_int_3,
        checksum_check_next
    );




    always_ff @(posedge i_clk or posedge i_arst)
    if (i_arst)
        state <= X_RESET;
    else begin
        state <= next_state;
        s_axis_tdata_prev <= s_axis_tdata;
        s_axis_tvalid_prev <= s_axis_tvalid;
        s_axis_tready_prev <= s_axis_tready;
        if (!s_axis_tvalid_prev)
            checksum_check <= 0;
        else if (s_axis_tvalid_prev & s_axis_tready_prev)
            checksum_check <= checksum_check_next;

        case (state)
            X_RESET: begin
                invalid <= 0;

                ihl <= 0;
                packet_length <= 0;
                identification <= 0;
                protocol <= 0;
                source_address <= 0;
                destination_address <= 0;

                word_count <= 0;
                checksum_check <= 0;
            end
            X_READ: begin
                if (s_axis_tvalid && s_axis_tready) begin
                    word_count <= word_count + 1;
                end
                
                case (word_count)
                4'd0: begin // Version, IHL, DSCP, ECN, Length, Identification, Flags, Fragment Offset
                    invalid <= s_axis_tdata[7:4] != 4'd4 // Version
                        | s_axis_tdata[3:0] < 5; // IHL
                    ihl <= s_axis_tdata[3:0]; // IHL
                    packet_length <= {s_axis_tdata[23:16], s_axis_tdata[31:24]};
                    identification  <= {s_axis_tdata[39:32], s_axis_tdata[47:40]};
                end
                4'd1: begin // TTL, Protocol, Checksum, Source Address
                    protocol <= s_axis_tdata[15:8];
                    source_address <= {<<8{s_axis_tdata[63:32]}};
                end
                4'd2: // Destination Address, Options?
                    destination_address <= {<<8{s_axis_tdata[31:0]}};
                default: begin end
                endcase
            end
            default: begin end
        endcase
    end

    always_comb
    case (state)
        X_RESET: next_state = X_READ;
        X_READ : next_state = last_dword ? X_RESET : X_READ;
        default: next_state = X_RESET;
    endcase

    always_comb begin
        s_axis_tready = state == X_READ;
        decode_done = state == X_RESET;
        header_valid = decode_done & !invalid & &checksum_check_next;
        header_tkeep = last_dword ? (ihl[0] ? 2'b01 : 2'b11) : 0;
        s_axis_tlast  = last_dword;
    end

endmodule
