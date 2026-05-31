module ipv4_header_decode #(

) (
    input wire i_clk,
    input wire i_arst,

    input  wire        s_axis_tvalid,
    input  wire [31:0] s_axis_tdata,
    output logic       s_axis_tready,
    output logic       s_axis_tdone,

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
        s_axis_tdata[15:0],
        checksum_check_int
    );
    
    ones_complement_adder checksum_adder_2 (
        checksum_check_int,
        s_axis_tdata[31:16],
        checksum_check_next
    );

    wire last_dword = s_axis_tvalid && |word_count && word_count == (ihl - 1);

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
                4'd0: begin
                    invalid <= invalid | s_axis_tdata[3:0] != 4'd4 | s_axis_tdata[7:4] < 5;
                    ihl <= s_axis_tdata[7:4];
                    packet_length <= {s_axis_tdata[23:16], s_axis_tdata[31:24]};
                end
                4'd1:
                    identification <= {s_axis_tdata[7:0], s_axis_tdata[15:8]};
                4'd2:
                    protocol <= s_axis_tdata[15:8];
                4'd3:
                    source_address <= {s_axis_tdata[7:0], s_axis_tdata[15:8], s_axis_tdata[23:16], s_axis_tdata[31:24]};
                4'd4:
                    destination_address <= {s_axis_tdata[7:0], s_axis_tdata[15:8], s_axis_tdata[23:16], s_axis_tdata[31:24]};
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
        s_axis_tdone  = state == X_RESET;
    end

endmodule

module ones_complement_adder #(parameter N=16) (
    input  wire [N-1:0] a,
    input  wire [N-1:0] b,
    output wire [N-1:0] sum
);
    wire [N:0] full_sum;
    assign full_sum = a + b;

    assign sum = full_sum[N-1:0] + {{(N-1){1'b0}}, full_sum[N]};

endmodule