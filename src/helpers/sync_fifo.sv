module sync_fifo #(
    parameter DATA_WIDTH = 32,
    parameter ADDRESS_WIDTH = 8
) (
    input wire i_clk,
    input wire i_arst,

    input  wire  [DATA_WIDTH-1:0] s_tdata,
    input  wire                   s_tvalid,
    output logic                  s_tready,
    
    output logic [DATA_WIDTH-1:0] m_tdata,
    output logic                  m_tvalid,
    input  wire                   m_tready
);

    logic [ADDRESS_WIDTH-1:0] waddr, raddr;
    logic [ADDRESS_WIDTH:0]   wbin, rbin;
    logic [ADDRESS_WIDTH:0] wbin_next, rbin_next;
    logic                     wfull_next, rempty_next;

    reg   [DATA_WIDTH-1:0] mem [0:((1 << ADDRESS_WIDTH) - 1)];

    initial {wbin, s_tready} = 0;
    always_ff @(posedge i_clk or posedge i_arst)
    if (i_arst)
        {wbin, s_tready} <= 0;
    else
        {wbin, s_tready} <= {wbin_next, !wfull_next};


    initial {rbin, m_tvalid} = 0;
    always_ff @(posedge i_clk or posedge i_arst)
    if (i_arst)
        {rbin, m_tvalid} <= 0;
    else
        {rbin, m_tvalid} <= {rbin_next, !rempty_next};
    

    always_comb begin
        wbin_next = wbin + (s_tvalid & s_tready ? 1 : 0);
        wfull_next = wbin_next == {!rbin[ADDRESS_WIDTH], rbin[ADDRESS_WIDTH-1:0]};

        rbin_next = rbin + (m_tready & m_tvalid ? 1 : 0);
        rempty_next = rbin_next == wbin;

        raddr = rbin[ADDRESS_WIDTH-1:0];
        waddr = wbin[ADDRESS_WIDTH-1:0];
    end

    assign m_tdata = mem[raddr];

    always_ff @(posedge i_clk)
    if (s_tvalid & s_tready)
        mem[waddr] <= s_tdata;

endmodule