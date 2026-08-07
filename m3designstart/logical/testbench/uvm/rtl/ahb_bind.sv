module ahb_bind
(
    input logic        HCLK,
    input logic        SYSRESETn,

    //===========================
    // I Bus
    //===========================
    input logic [1:0]  HTRANSI,
    input logic [2:0]  HSIZEI,
    input logic [31:0] HADDRI,
    input logic [2:0]  HBURSTI,
    input logic [3:0]  HPROTI,
    input logic [1:0]  MEMATTRI,
    input logic        HREADYI,
    input logic [31:0] HRDATAI,
    input logic [1:0]  HRESPI,

    //===========================
    // D Bus
    //===========================
    input logic [1:0]  HTRANSD,
    input logic [2:0]  HSIZED,
    input logic [31:0] HADDRD,
    input logic [2:0]  HBURSTD,
    input logic [3:0]  HPROTD,
    input logic [1:0]  MEMATTRD,
    input logic  [1:0]      HMASTERD,
    input logic        EXREQD,
    input logic        HWRITED,
    input logic [31:0] HWDATAD,
    input logic        HREADYD,
    input logic [31:0] HRDATAD,
    input logic [1:0]  HRESPD,
    input logic        EXRESPD,

    //===========================
    // S Bus
    //===========================
    input logic [1:0]  HTRANSS,
    input logic [2:0]  HSIZES,
    input logic [31:0] HADDRS,
    input logic [2:0]  HBURSTS,
    input logic [3:0]  HPROTS,
    input logic [1:0]  MEMATTRS,
    input logic [1:0]      HMASTERS,
    input logic        EXREQS,
    input logic        HWRITES,
    input logic [31:0] HWDATAS,
    input logic        HMASTLOCKS,
    input logic        HREADYS,
    input logic [31:0] HRDATAS,
    input logic [1:0]  HRESPS,
    input logic        EXRESPS
);

    ahb_if ahb_vif(
        .HCLK    (HCLK),
        .HRESETn (SYSRESETn)
    );

    //-------------------------
    // I Bus
    //-------------------------
    assign ahb_vif.HTRANSI   = HTRANSI;
    assign ahb_vif.HSIZEI    = HSIZEI;
    assign ahb_vif.HADDRI    = HADDRI;
    assign ahb_vif.HBURSTI   = HBURSTI;
    assign ahb_vif.HPROTI    = HPROTI;
    assign ahb_vif.MEMATTRI  = MEMATTRI;
    assign ahb_vif.HREADYI   = HREADYI;
    assign ahb_vif.HRDATAI   = HRDATAI;
    assign ahb_vif.HRESPI    = HRESPI;

    //-------------------------
    // D Bus
    //-------------------------
    assign ahb_vif.HTRANSD   = HTRANSD;
    assign ahb_vif.HSIZED    = HSIZED;
    assign ahb_vif.HADDRD    = HADDRD;
    assign ahb_vif.HBURSTD   = HBURSTD;
    assign ahb_vif.HPROTD    = HPROTD;
    assign ahb_vif.MEMATTRD  = MEMATTRD;
    assign ahb_vif.HMASTERD  = HMASTERD;
    assign ahb_vif.EXREQD    = EXREQD;
    assign ahb_vif.HWRITED   = HWRITED;
    assign ahb_vif.HWDATAD   = HWDATAD;
    assign ahb_vif.HREADYD   = HREADYD;
    assign ahb_vif.HRDATAD   = HRDATAD;
    assign ahb_vif.HRESPD    = HRESPD;
    assign ahb_vif.EXRESPD   = EXRESPD;

    //-------------------------
    // S Bus
    //-------------------------
    assign ahb_vif.HTRANSS    = HTRANSS;
    assign ahb_vif.HSIZES     = HSIZES;
    assign ahb_vif.HADDRS     = HADDRS;
    assign ahb_vif.HBURSTS    = HBURSTS;
    assign ahb_vif.HPROTS     = HPROTS;
    assign ahb_vif.MEMATTRS   = MEMATTRS;
    assign ahb_vif.HMASTERS   = HMASTERS;
    assign ahb_vif.EXREQS     = EXREQS;
    assign ahb_vif.HWRITES    = HWRITES;
    assign ahb_vif.HWDATAS    = HWDATAS;
    assign ahb_vif.HMASTLOCKS = HMASTLOCKS;
    assign ahb_vif.HREADYS    = HREADYS;
    assign ahb_vif.HRDATAS    = HRDATAS;
    assign ahb_vif.HRESPS     = HRESPS;
    assign ahb_vif.EXRESPS    = EXRESPS;

endmodule














