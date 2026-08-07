`ifndef AXI_IF_SV
`define AXI_IF_SV

interface axi_if #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter ID_WIDTH   = 4
)(
    input ACLK,
    input ARESETn
);

    //=========================================================
    // Instruction Bus (I Bus)
    //=========================================================

    //--------------- Read Address Channel --------------------
    logic [ID_WIDTH-1:0]         i_arid;
    logic [ADDR_WIDTH-1:0]       i_araddr;
    logic [7:0]                  i_arlen;
    logic [2:0]                  i_arsize;
    logic [1:0]                  i_arburst;
    logic                        i_arvalid;
    logic                        i_arready;

    //--------------- Read Data Channel -----------------------
    logic [ID_WIDTH-1:0]         i_rid;
    logic [DATA_WIDTH-1:0]       i_rdata;
    logic [1:0]                  i_rresp;
    logic                        i_rlast;
    logic                        i_rvalid;
    logic                        i_rready;


    //=========================================================
    // Data Bus (D Bus)
    //=========================================================

    //--------------- Write Address Channel -------------------
    logic [ID_WIDTH-1:0]         d_awid;
    logic [ADDR_WIDTH-1:0]       d_awaddr;
    logic [7:0]                  d_awlen;
    logic [2:0]                  d_awsize;
    logic [1:0]                  d_awburst;
    logic                        d_awvalid;
    logic                        d_awready;

    //--------------- Write Data Channel ----------------------
    logic [DATA_WIDTH-1:0]       d_wdata;
    logic [(DATA_WIDTH/8)-1:0]   d_wstrb;
    logic                        d_wlast;
    logic                        d_wvalid;
    logic                        d_wready;

    //--------------- Write Response Channel ------------------
    logic [ID_WIDTH-1:0]         d_bid;
    logic [1:0]                  d_bresp;
    logic                        d_bvalid;
    logic                        d_bready;

    //--------------- Read Address Channel --------------------
    logic [ID_WIDTH-1:0]         d_arid;
    logic [ADDR_WIDTH-1:0]       d_araddr;
    logic [7:0]                  d_arlen;
    logic [2:0]                  d_arsize;
    logic [1:0]                  d_arburst;
    logic                        d_arvalid;
    logic                        d_arready;

    //--------------- Read Data Channel -----------------------
    logic [ID_WIDTH-1:0]         d_rid;
    logic [DATA_WIDTH-1:0]       d_rdata;
    logic [1:0]                  d_rresp;
    logic                        d_rlast;
    logic                        d_rvalid;
    logic                        d_rready;


    //=========================================================
    // System Bus (S Bus)
    //=========================================================

    //--------------- Write Address Channel -------------------
    logic [ID_WIDTH-1:0]         s_awid;
    logic [ADDR_WIDTH-1:0]       s_awaddr;
    logic [7:0]                  s_awlen;
    logic [2:0]                  s_awsize;
    logic [1:0]                  s_awburst;
    logic                        s_awvalid;
    logic                        s_awready;

    //--------------- Write Data Channel ----------------------
    logic [DATA_WIDTH-1:0]       s_wdata;
    logic [(DATA_WIDTH/8)-1:0]   s_wstrb;
    logic                        s_wlast;
    logic                        s_wvalid;
    logic                        s_wready;

    //--------------- Write Response Channel ------------------
    logic [ID_WIDTH-1:0]         s_bid;
    logic [1:0]                  s_bresp;
    logic                        s_bvalid;
    logic                        s_bready;

    //--------------- Read Address Channel --------------------
    logic [ID_WIDTH-1:0]         s_arid;
    logic [ADDR_WIDTH-1:0]       s_araddr;
    logic [7:0]                  s_arlen;
    logic [2:0]                  s_arsize;
    logic [1:0]                  s_arburst;
    logic                        s_arvalid;
    logic                        s_arready;

    //--------------- Read Data Channel -----------------------
    logic [ID_WIDTH-1:0]         s_rid;
    logic [DATA_WIDTH-1:0]       s_rdata;
    logic [1:0]                  s_rresp;
    logic                        s_rlast;
    logic                        s_rvalid;
    logic                        s_rready;

endinterface

`endif
