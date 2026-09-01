//-----------------------------------------------------------------------------
// APB interface for cmsdk_apb_watchdog. Carries the register-access side of
// the DUT (PCLK domain). Driven by wdog_apb_driver, sampled by
// wdog_apb_monitor.
//-----------------------------------------------------------------------------
interface wdog_apb_if (input bit PCLK);

  logic         PRESETn;
  logic         PSEL;
  logic         PENABLE;
  logic         PWRITE;
  logic [11:2]  PADDR;
  logic [31:0]  PWDATA;
  logic [31:0]  PRDATA;

  clocking drv_cb @(posedge PCLK);
    output PRESETn, PSEL, PENABLE, PWRITE, PADDR, PWDATA;
    input  PRDATA;
  endclocking

  clocking mon_cb @(posedge PCLK);
    input PRESETn, PSEL, PENABLE, PWRITE, PADDR, PWDATA, PRDATA;
  endclocking

  modport DRIVER (clocking drv_cb);
  modport MONITOR(clocking mon_cb);

endinterface : wdog_apb_if
