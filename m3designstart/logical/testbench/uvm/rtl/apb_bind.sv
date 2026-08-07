module apb_bind
(
    input logic        PCLK,
    input logic        PRESETn,

    //===========================
    // I Bus
    //===========================
    input logic        PSELI,
    input logic        PENABLEI,
   // input logic        PWRITEI,
    input logic [31:0] PADDRI,
  //  input logic [31:0] PWDATAI,
    input logic [31:0] PRDATAI,
    input logic        PREADYI,
    input logic        PSLVERRI,

    //===========================
    // D Bus
    //===========================
    input logic        PSELD,
    input logic        PENABLED,
    input logic        PWRITED,
    input logic [31:0] PADDRD,
    input logic [31:0] PWDATAD,
    input logic [31:0] PRDATAD,
    input logic        PREADYD,
    input logic        PSLVERRD,

    //===========================
    // S Bus
    //===========================
    input logic        PSELS,
    input logic        PENABLES,
    input logic        PWRITES,
    input logic [31:0] PADDRS,
    input logic [31:0] PWDATAS,
    input logic [31:0] PRDATAS,
    input logic        PREADYS,
    input logic        PSLVERRS
);

    apb_if apb_vif
    (
        .PCLK    (PCLK),
        .PRESETn (PRESETn)
    );

    //-------------------------
    // I Bus
    //-------------------------
    assign apb_vif.i_psel     = PSELI;
    assign apb_vif.i_penable  = PENABLEI;
  //  assign apb_vif.i_pwrite   = PWRITEI;  //this is optional
    assign apb_vif.i_paddr    = PADDRI;
  //  assign apb_vif.i_pwdata   = PWDATAI;   //this is optional
    assign apb_vif.i_prdata   = PRDATAI;
    assign apb_vif.i_pready   = PREADYI;
    assign apb_vif.i_pslverr  = PSLVERRI;

    //-------------------------
    // D Bus
    //-------------------------
    assign apb_vif.d_psel     = PSELD;
    assign apb_vif.d_penable  = PENABLED;
    assign apb_vif.d_pwrite   = PWRITED;
    assign apb_vif.d_paddr    = PADDRD;
    assign apb_vif.d_pwdata   = PWDATAD;
    assign apb_vif.d_prdata   = PRDATAD;
    assign apb_vif.d_pready   = PREADYD;
    assign apb_vif.d_pslverr  = PSLVERRD;

    //-------------------------
    // S Bus
    //-------------------------
    assign apb_vif.s_psel     = PSELS;
    assign apb_vif.s_penable  = PENABLES;
    assign apb_vif.s_pwrite   = PWRITES;
    assign apb_vif.s_paddr    = PADDRS;
    assign apb_vif.s_pwdata   = PWDATAS;
    assign apb_vif.s_prdata   = PRDATAS;
    assign apb_vif.s_pready   = PREADYS;
    assign apb_vif.s_pslverr  = PSLVERRS;

endmodule
