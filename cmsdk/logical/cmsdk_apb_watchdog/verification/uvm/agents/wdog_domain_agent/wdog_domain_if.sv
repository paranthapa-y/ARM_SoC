//-----------------------------------------------------------------------------
// WDOGCLK-domain interface for cmsdk_apb_watchdog. Carries the counter side
// of the DUT: the clock-enable / async-reset controls that gate it, and the
// two outputs (WDOGINT/WDOGRES) that result. WDOGCLK itself is generated in
// tb_top (free-running) and only sampled here.
//-----------------------------------------------------------------------------
interface wdog_domain_if (input bit WDOGCLK);

  logic        WDOGCLKEN;
  logic        WDOGRESn;
  logic [3:0]  ECOREVNUM;
  logic        WDOGINT;
  logic        WDOGRES;

  clocking drv_cb @(posedge WDOGCLK);
    output WDOGCLKEN, WDOGRESn, ECOREVNUM;
  endclocking

  // #0 input skew (not the clocking-block default #1step): WDOGINT/WDOGRES
  // are DUT registers clocked on this very same WDOGCLK edge. The default
  // skew samples the pre-edge (previous-tick) value, which is correct for
  // avoiding driver/DUT races but wrong for a monitor that wants to see
  // what the DUT just latched THIS edge -- with the default skew every
  // prediction the live counter model makes for "this tick" lines up
  // against what the monitor reports as "last tick", a constant one-tick
  // skew that shows up as scoreboard mismatches on every state change.
  clocking mon_cb @(posedge WDOGCLK);
    default input #0;
    input WDOGCLKEN, WDOGRESn, ECOREVNUM, WDOGINT, WDOGRES;
  endclocking

  modport DRIVER (clocking drv_cb);
  modport MONITOR(clocking mon_cb);

endinterface : wdog_domain_if
