module block_lock_sm(
    input wire rst_a,
    input wire clk_rx,
    input wire [1:0] rx_header,

    output reg gearbox_slip,
    output wire block_lock
);

    reg rx_block_lock;
    reg set_block_lock, reset_block_lock;

    reg [6:0] sh_cnt;
    reg inc_sh_cnt, reset_sh_count;

    reg [5:0] sh_invalid_cnt;
    reg inc_sh_invalid_cnt, reset_invalid_sh_count;

    reg [2:0] state;
    reg [2:0] state_next;

    wire sh_valid = ^rx_header; // 01 or 10 are valid headers

    localparam X_LOCK_INIT  = 3'd0;
    localparam X_RESET_CNT  = 3'd1;
    localparam X_TEST_SH    = 3'd2;
    localparam X_64_GOOD    = 3'd3;
    localparam X_SLIP       = 3'd4;

    always_ff @(posedge clk_rx or posedge rst_a) begin
        if (rst_a) begin
            state <= X_LOCK_INIT;

            rx_block_lock <= 1'b0;
            sh_cnt <= 7'b0;
            sh_invalid_cnt <= 6'b0;
        end else begin
            state <= state_next;

            rx_block_lock <= set_block_lock ? 1'b1 : reset_block_lock ? 1'b0 : rx_block_lock;
            sh_cnt <= inc_sh_cnt ? sh_cnt + 1'b1 : reset_sh_count ? 0 : sh_cnt;
            sh_invalid_cnt <= inc_sh_invalid_cnt ? sh_invalid_cnt + 1'b1 : reset_invalid_sh_count ? 0 : sh_invalid_cnt;
        end
    end

    always_comb begin
        case (state)
            X_LOCK_INIT : state_next = X_RESET_CNT;
            X_RESET_CNT : state_next = X_TEST_SH;
            X_TEST_SH   : begin
                if (sh_valid)
                    state_next = (sh_cnt == 7'd64 & sh_invalid_cnt == 0) ? X_64_GOOD : (sh_cnt == 7'd64) ? X_RESET_CNT : X_TEST_SH; 
                else
                    state_next = (sh_invalid_cnt == 6'd16) ? X_SLIP : (sh_cnt == 7'd64) ? X_RESET_CNT : X_TEST_SH;
            end
            X_64_GOOD   : state_next = X_RESET_CNT;
            X_SLIP      : state_next = X_RESET_CNT;
            default: state_next = X_LOCK_INIT;
        endcase
    end

    always_comb begin
        set_block_lock         = state == X_64_GOOD;
        reset_block_lock       = state == X_SLIP | state == X_LOCK_INIT;
        reset_sh_count         = state == X_RESET_CNT;
        reset_invalid_sh_count = state == X_RESET_CNT;
        
        inc_sh_cnt             = state == X_TEST_SH;
        inc_sh_invalid_cnt     = state == X_TEST_SH & !sh_valid;

        gearbox_slip           = state == X_SLIP;
    end

    assign block_lock = rx_block_lock;
endmodule