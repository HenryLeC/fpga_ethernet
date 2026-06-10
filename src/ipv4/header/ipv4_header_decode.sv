module ipv4_header_decode #(

) (
    input wire i_clk,
    input wire i_arst,

    input  wire [31:0] s_axis_tdata,
    input  wire        s_axis_tvalid,
    output logic       s_axis_tready,
    output logic       s_axis_tlast, // This is the wrong direction for a compliant axi stream
                                     // but in this case the master does not know when the headier
                                     // is finished.

    output logic      decode_done,
    output reg        header_valid,

    output reg [15:0] packet_length,
    output reg [15:0] identification,
    output reg [ 7:0] protocol,
    output reg [31:0] source_address,
    output reg [31:0] destination_address
);

    reg state = X_RESET;
    logic next_state;

    localparam X_RESET = 1'd0;;
    localparam X_READ  = 1'd1;

    reg invalid;
    reg [3:0] word_count;
    reg [3:0] ihl;

    reg  [15:0] checksum_check;
    wire [15:0] checksum_check_int;
    wire [15:0] checksum_check_next;
    ones_complement_adder checksum_adder_1 (
        checksum_check,
        |word_count ? s_axis_tdata[15:0] : 16'h0, // Don't add EtherType on dword 0
        checksum_check_int
    );
    
    ones_complement_adder checksum_adder_2 (
        checksum_check_int,
        last_dword ? 16'h0 : s_axis_tdata[31:16], // Don't add start of packet on last dword
        checksum_check_next
    );

    wire last_dword = s_axis_tvalid && |word_count && word_count == (ihl);

    always_ff @(posedge i_clk or posedge i_arst)
    if (i_arst)
        state <= X_RESET;
    else begin
        state <= next_state;
        case (state)
            X_RESET: begin
                invalid <= 0;

                header_valid <= 0;
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
                    checksum_check <= checksum_check_next;
                end
                
                case (word_count)
                4'd0: begin // EtherType, Version, IHL, DSCP, ECN
                    invalid <= s_axis_tdata[15:0] != 16'h0008 // EtherType
                        | s_axis_tdata[23:20] != 4'd4 // Version
                        | s_axis_tdata[19:16] < 5; // IHL
                    ihl <= s_axis_tdata[19:16]; // IHL
                end
                4'd1: begin // Total Length, Identification
                    identification  <= {s_axis_tdata[23:16], s_axis_tdata[31:24]};
                    packet_length <= {s_axis_tdata[7:0], s_axis_tdata[15:8]};
                end
                4'd2: // Flags, Fragment Offset, TTL, Protocol
                    protocol <= s_axis_tdata[31:24];
                4'd3: // Header Checksum, Source Address[15:0]
                    source_address <= {s_axis_tdata[23:16], s_axis_tdata[31:24], 16'h0};
                4'd4: begin // Source Address[31:16], Destination Address [15:0]
                    source_address <= {source_address[31:16], s_axis_tdata[7:0], s_axis_tdata[15:8]};
                    destination_address <= {s_axis_tdata[23:16], s_axis_tdata[31:24], 16'h0};
                end
                4'd5: // Destination Address [15:0], Options?[15:0]
                    destination_address <= {destination_address[31:16], s_axis_tdata[7:0], s_axis_tdata[15:8]};
                default: begin end
                endcase

                if (last_dword) begin
                    header_valid <= !invalid && &checksum_check_next; // Not packet invalid and checksum next == FFFFFFFF
                end
            end
        endcase
    end

    always_comb
    case (state)
        X_RESET: next_state = X_READ;
        X_READ : next_state = last_dword ? X_RESET : X_READ;
    endcase

    always_comb begin
        s_axis_tready = state == X_READ;
        decode_done = state == X_RESET;
        s_axis_tlast  = last_dword;
    end

endmodule
