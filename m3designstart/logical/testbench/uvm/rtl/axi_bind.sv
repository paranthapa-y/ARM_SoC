module axi_bind
(
    input logic        ACLK,
    input logic        ARESETn,

    //=========================================================
    // Instruction Bus (I Bus)
    //=========================================================

    // Read Address Channel
    input logic [3:0]  I_ARID,
    input logic [31:0] I_ARADDR,
    input logic [7:0]  I_ARLEN,
    input logic [2:0]  I_ARSIZE,
    input logic [1:0]  I_ARBURST,
    input logic        I_ARVALID,
    input logic        I_ARREADY,

    // Read Data Channel
    input logic [3:0]  I_RID,
    input logic [31:0] I_RDATA,
    input logic [1:0]  I_RRESP,
    input logic        I_RLAST,
    input logic        I_RVALID,
    input logic        I_RREADY,


    //=========================================================
    // Data Bus (D Bus)
    //=========================================================

    // Write Address Channel
    input logic [3:0]  D_AWID,
    input logic [31:0] D_AWADDR,
    input logic [7:0]  D_AWLEN,
    input logic [2:0]  D_AWSIZE,
    input logic [1:0]  D_AWBURST,
    input logic        D_AWVALID,
    input logic        D_AWREADY,

    // Write Data Channel
    input logic [31:0] D_WDATA,
    input logic [3:0]  D_WSTRB,
    input logic        D_WLAST,
    input logic        D_WVALID,
    input logic        D_WREADY,

    // Write Response Channel
    input logic [3:0]  D_BID,
    input logic [1:0]  D_BRESP,
    input logic        D_BVALID,
    input logic        D_BREADY,

    // Read Address Channel
    input logic [3:0]  D_ARID,
    input logic [31:0] D_ARADDR,
    input logic [7:0]  D_ARLEN,
    input logic [2:0]  D_ARSIZE,
    input logic [1:0]  D_ARBURST,
    input logic        D_ARVALID,
    input logic        D_ARREADY,

    // Read Data Channel
    input logic [3:0]  D_RID,
    input logic [31:0] D_RDATA,
    input logic [1:0]  D_RRESP,
    input logic        D_RLAST,
    input logic        D_RVALID,
    input logic        D_RREADY,


    //=========================================================
    // System Bus (S Bus)
    //=========================================================

    // Write Address Channel
    input logic [3:0]  S_AWID,
    input logic [31:0] S_AWADDR,
    input logic [7:0]  S_AWLEN,
    input logic [2:0]  S_AWSIZE,
    input logic [1:0]  S_AWBURST,
    input logic        S_AWVALID,
    input logic        S_AWREADY,

    // Write Data Channel
    input logic [31:0] S_WDATA,
    input logic [3:0]  S_WSTRB,
    input logic        S_WLAST,
    input logic        S_WVALID,
    input logic        S_WREADY,

    // Write Response Channel
    input logic [3:0]  S_BID,
    input logic [1:0]  S_BRESP,
    input logic        S_BVALID,
    input logic        S_BREADY,

    // Read Address Channel
    input logic [3:0]  S_ARID,
    input logic [31:0] S_ARADDR,
    input logic [7:0]  S_ARLEN,
    input logic [2:0]  S_ARSIZE,
    input logic [1:0]  S_ARBURST,
    input logic        S_ARVALID,
    input logic        S_ARREADY,

    // Read Data Channel
    input logic [3:0]  S_RID,
    input logic [31:0] S_RDATA,
    input logic [1:0]  S_RRESP,
    input logic        S_RLAST,
    input logic        S_RVALID,
    input logic        S_RREADY
);

    axi_if axi_vif
    (
        .ACLK    (ACLK),
        .ARESETn (ARESETn)
    );

    //=========================================================
    // I Bus
    //=========================================================

    assign axi_vif.i_arid    = I_ARID;
    assign axi_vif.i_araddr  = I_ARADDR;
    assign axi_vif.i_arlen   = I_ARLEN;
    assign axi_vif.i_arsize  = I_ARSIZE;
    assign axi_vif.i_arburst = I_ARBURST;
    assign axi_vif.i_arvalid = I_ARVALID;
    assign axi_vif.i_arready = I_ARREADY;

    assign axi_vif.i_rid     = I_RID;
    assign axi_vif.i_rdata   = I_RDATA;
    assign axi_vif.i_rresp   = I_RRESP;
    assign axi_vif.i_rlast   = I_RLAST;
    assign axi_vif.i_rvalid  = I_RVALID;
    assign axi_vif.i_rready  = I_RREADY;


    //=========================================================
    // D Bus
    //=========================================================

    assign axi_vif.d_awid    = D_AWID;
    assign axi_vif.d_awaddr  = D_AWADDR;
    assign axi_vif.d_awlen   = D_AWLEN;
    assign axi_vif.d_awsize  = D_AWSIZE;
    assign axi_vif.d_awburst = D_AWBURST;
    assign axi_vif.d_awvalid = D_AWVALID;
    assign axi_vif.d_awready = D_AWREADY;

    assign axi_vif.d_wdata   = D_WDATA;
    assign axi_vif.d_wstrb   = D_WSTRB;
    assign axi_vif.d_wlast   = D_WLAST;
    assign axi_vif.d_wvalid  = D_WVALID;
    assign axi_vif.d_wready  = D_WREADY;

    assign axi_vif.d_bid     = D_BID;
    assign axi_vif.d_bresp   = D_BRESP;
    assign axi_vif.d_bvalid  = D_BVALID;
    assign axi_vif.d_bready  = D_BREADY;

    assign axi_vif.d_arid    = D_ARID;
    assign axi_vif.d_araddr  = D_ARADDR;
    assign axi_vif.d_arlen   = D_ARLEN;
    assign axi_vif.d_arsize  = D_ARSIZE;
    assign axi_vif.d_arburst = D_ARBURST;
    assign axi_vif.d_arvalid = D_ARVALID;
    assign axi_vif.d_arready = D_ARREADY;

    assign axi_vif.d_rid     = D_RID;
    assign axi_vif.d_rdata   = D_RDATA;
    assign axi_vif.d_rresp   = D_RRESP;
    assign axi_vif.d_rlast   = D_RLAST;
    assign axi_vif.d_rvalid  = D_RVALID;
    assign axi_vif.d_rready  = D_RREADY;


    //=========================================================
    // S Bus
    //=========================================================

    assign axi_vif.s_awid    = S_AWID;
    assign axi_vif.s_awaddr  = S_AWADDR;
    assign axi_vif.s_awlen   = S_AWLEN;
    assign axi_vif.s_awsize  = S_AWSIZE;
    assign axi_vif.s_awburst = S_AWBURST;
    assign axi_vif.s_awvalid = S_AWVALID;
    assign axi_vif.s_awready = S_AWREADY;

    assign axi_vif.s_wdata   = S_WDATA;
    assign axi_vif.s_wstrb   = S_WSTRB;
    assign axi_vif.s_wlast   = S_WLAST;
    assign axi_vif.s_wvalid  = S_WVALID;
    assign axi_vif.s_wready  = S_WREADY;

    assign axi_vif.s_bid     = S_BID;
    assign axi_vif.s_bresp   = S_BRESP;
    assign axi_vif.s_bvalid  = S_BVALID;
    assign axi_vif.s_bready  = S_BREADY;

    assign axi_vif.s_arid    = S_ARID;
    assign axi_vif.s_araddr  = S_ARADDR;
    assign axi_vif.s_arlen   = S_ARLEN;
    assign axi_vif.s_arsize  = S_ARSIZE;
    assign axi_vif.s_arburst = S_ARBURST;
    assign axi_vif.s_arvalid = S_ARVALID;
    assign axi_vif.s_arready = S_ARREADY;

    assign axi_vif.s_rid     = S_RID;
    assign axi_vif.s_rdata   = S_RDATA;
    assign axi_vif.s_rresp   = S_RRESP;
    assign axi_vif.s_rlast   = S_RLAST;
    assign axi_vif.s_rvalid  = S_RVALID;
    assign axi_vif.s_rready  = S_RREADY;

endmodule
