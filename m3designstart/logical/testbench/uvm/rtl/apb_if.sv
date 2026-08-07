interface apb_if #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input logic PCLK,
    input logic PRESETn
);

    //==========================================================
    // Instruction Bus (I-Bus)
    //==========================================================
    logic                    i_psel;
    logic                    i_penable;
    logic                    i_pwrite;    //this is optional

    logic [ADDR_WIDTH-1:0]   i_paddr;
    logic [DATA_WIDTH-1:0]   i_pwdata;    //this is optional
    logic [DATA_WIDTH-1:0]   i_prdata;

    logic                    i_pready;
    logic                    i_pslverr;


    //==========================================================
    // Data Bus (D-Bus)
    //==========================================================
    logic                    d_psel;
    logic                    d_penable;
    logic                    d_pwrite;

    logic [ADDR_WIDTH-1:0]   d_paddr;
    logic [DATA_WIDTH-1:0]   d_pwdata;
    logic [DATA_WIDTH-1:0]   d_prdata;

    logic                    d_pready;
    logic                    d_pslverr;


    //==========================================================
    // System Bus (S-Bus)
    //==========================================================
    logic                    s_psel;
    logic                    s_penable;
    logic                    s_pwrite;

    logic [ADDR_WIDTH-1:0]   s_paddr;
    logic [DATA_WIDTH-1:0]   s_pwdata;
    logic [DATA_WIDTH-1:0]   s_prdata;

    logic                    s_pready;
    logic                    s_pslverr;

endinterface
