module async_fifo #(
    parameter DATA_WIDTH = 72,
    parameter ADDRESS_WIDTH = 3
) (
    input  wire                  i_wclk,
    input  wire                  i_wrst,
    input  wire                  i_wr,
    input  wire [DATA_WIDTH-1:0] i_wdata,
    output reg                   o_wfull,
    input  wire                  i_rclk,
    input  wire                  i_rrst,
    input  wire                  i_rd,
    output wire [DATA_WIDTH-1:0] o_rdata,
    output reg                   o_rempty
);

    wire [ADDRESS_WIDTH-1:0] waddr, raddr;
    wire                     wfull_next, rempty_next;
    reg  [ADDRESS_WIDTH:0]   wgray, wbin, wq2_rgray, wql_rgray,
                             rgray, rbin, rq2_wgray, rql_wgray;

    wire [ADDRESS_WIDTH:0]   wgraynext, wbinnext,
                             rgraynext, rbinnext;

    reg [DATA_WIDTH-1:0] mem [0:((1<<ADDRESS_WIDTH)-1)]; // Infer the memory

    //
    // Clock Domain Crossing
    //

    // Cross read Gray pointers into write clock domain
    initial {wq2_rgray, wql_rgray} = 0;
    always_ff @(posedge i_wclk or posedge i_wrst)
    if (i_wrst)
        {wq2_rgray, wql_rgray} <= 0;
    else
        {wq2_rgray, wql_rgray} <= {wql_rgray, rgray};

    // Cross write gray pointers into read clock domain
    initial {rq2_wgray, rql_wgray} = 0;
    always_ff @(posedge i_rclk or posedge i_rrst)
    if (i_rrst)
        {rq2_wgray, rql_wgray} <= 0;
    else
        {rq2_wgray, rql_wgray} <= {rql_wgray, wgray};

    
    //
    // Write Side
    //
    // Next address and gray code
    assign wbinnext = wbin + { {(ADDRESS_WIDTH){1'b0}}, ((i_wr) && (!o_wfull))};
    assign wgraynext = (wbinnext >> 1) ^ wbinnext;

    // Register address and gray code
    initial {wbin, wgray} = 0;
    always_ff @(posedge i_wclk or posedge i_wrst)
    if (i_wrst)
        {wbin, wgray} <= 0;
    else
        {wbin, wgray} <= {wbinnext, wgraynext};

    // Resize write address
    assign waddr = wbin[ADDRESS_WIDTH-1:0];

    // Determine Write full
    assign wfull_next = wgraynext == {~wq2_rgray[ADDRESS_WIDTH:ADDRESS_WIDTH-1], wq2_rgray[ADDRESS_WIDTH-2:0]};

    // Register write full
    initial o_wfull = 0;
    always_ff @(posedge i_wclk or posedge i_wrst)
    if (i_wrst)
        o_wfull <= 0;
    else
        o_wfull <= wfull_next;

    // Write to the memory
    always_ff @(posedge i_wclk)
    if ((i_wr) && (!o_wfull))
        mem[waddr] <= i_wdata;

    
    //
    // Read Side
    //
    // Next address and gray code
    assign rbinnext = rbin + { {(ADDRESS_WIDTH){1'b0}}, ((i_rd) && (!o_rempty))};
    assign rgraynext = (rbinnext >> 1) ^ rbinnext;

    // Register address and gray code
    initial {rbin, rgray} = 0;
    always_ff @(posedge i_rclk or posedge i_rrst)
    if (i_rrst)
        {rbin, rgray} <= 0;
    else
        {rbin, rgray} <= {rbinnext, rgraynext};

    // Resize read address
    assign raddr = rbin[ADDRESS_WIDTH-1:0];

    // Determine read empty
    assign rempty_next = rgraynext == rq2_wgray;

    // Register read empty
    initial o_rempty = 0;
    always_ff @(posedge i_rclk or posedge i_rrst)
    if (i_rrst)
        o_rempty <= 0;
    else
        o_rempty <= rempty_next;

    // Read from memory
    assign o_rdata = mem[raddr];
endmodule