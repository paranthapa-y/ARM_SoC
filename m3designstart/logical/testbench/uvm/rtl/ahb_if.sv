`ifndef AHB_IF_SV
`define AHB_IF_SV

interface ahb_if #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input HCLK,
    input HRESETn
);
    //=========================================================
    // Clock and Reset
    //=========================================================

   // logic HCLK;
   // logic HRESETn;

    //=========================================================
    // Instruction Bus (I-Code Bus)
    //=========================================================

    // CPU -> Memory
    logic [1:0]                  HTRANSI;
    logic [2:0]                  HSIZEI;
    logic [ADDR_WIDTH-1:0]       HADDRI;
    logic [2:0]                  HBURSTI;
    logic [3:0]                  HPROTI;
    logic [1:0]                  MEMATTRI;

    // Memory -> CPU
    logic                        HREADYI;
    logic [DATA_WIDTH-1:0]       HRDATAI;
    logic [1:0]                  HRESPI;

    //=========================================================
    // Data Bus (D-Code Bus)
    //=========================================================

    // CPU -> Memory
    logic [1:0]                  HTRANSD;
    logic [2:0]                  HSIZED;
    logic [ADDR_WIDTH-1:0]       HADDRD;
    logic [2:0]                  HBURSTD;
    logic [3:0]                  HPROTD;
    logic [1:0]                  MEMATTRD;
    logic [1:0]                      HMASTERD;
    logic                        EXREQD;
    logic                        HWRITED;
    logic [DATA_WIDTH-1:0]       HWDATAD;

    // Memory -> CPU
    logic                        HREADYD;
    logic [DATA_WIDTH-1:0]       HRDATAD;
    logic [1:0]                  HRESPD;
    logic                        EXRESPD;

    //=========================================================
    // System Bus (S Bus)
    //=========================================================

    // CPU -> Memory
    logic [1:0]                  HTRANSS;
    logic [2:0]                  HSIZES;
    logic [ADDR_WIDTH-1:0]       HADDRS;
    logic [2:0]                  HBURSTS;
    logic [3:0]                  HPROTS;
    logic [1:0]                  MEMATTRS;
    logic [1:0]                       HMASTERS;
    logic                        EXREQS;
    logic                        HWRITES;
    logic [DATA_WIDTH-1:0]       HWDATAS;
    logic                        HMASTLOCKS;

    // Memory -> CPU
    logic                        HREADYS;
    logic [DATA_WIDTH-1:0]       HRDATAS;
    logic [1:0]                  HRESPS;
    logic                        EXRESPS;

endinterface

`endif
