//-----------------------------------------------------------------------------
// Drives WDOGCLKEN / WDOGRESn / ECOREVNUM. WDOGCLK itself is free-running,
// generated in tb_top -- this driver never touches it, matching how the
// real clock-enable / reset-domain controls are quasi-static signals from
// system logic, not per-transaction traffic.
//
// Defaults to idle (WDOGCLKEN=1, WDOGRESn=1) when no sequence is running,
// so the counter free-runs unless a test explicitly drives this agent.
//-----------------------------------------------------------------------------
class wdog_domain_driver extends uvm_driver #(wdog_domain_item);

  `uvm_component_utils(wdog_domain_driver)

  virtual wdog_domain_if.DRIVER vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual wdog_domain_if.DRIVER)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "wdog_domain_driver: virtual interface not set")
  endfunction

  task run_phase(uvm_phase phase);
    vif.drv_cb.WDOGCLKEN <= 1'b1;
    vif.drv_cb.WDOGRESn  <= 1'b1;
    vif.drv_cb.ECOREVNUM <= 4'h0;

    // Self-reset once at the start, same as wdog_apb_driver does for
    // PRESETn -- this MUST be the only place that ever drives WDOGRESn
    // during the automatic reset pulse. A second concurrent writer (e.g. a
    // test calling do_reset() directly while this task is also live) races
    // against this and can leave WDOGRESn never visibly low: wdog_ris/
    // i_wdog_res then keep their power-on X forever (unlike the counter,
    // which gets force-reloaded to a defined value by the next WDOGLOAD/
    // INTEN write regardless), and that X poisons WDOGRES permanently once
    // it ANDs into carry_msb. Found by hitting exactly this while bringing
    // the sanity sequence up -- do_reset() stays available for mid-test
    // reset-domain tests (GAP-5 style), just not concurrently with this.
    do_reset();

    forever begin
      wdog_domain_item item;
      seq_item_port.get_next_item(item);
      vif.drv_cb.WDOGCLKEN <= item.wdogclken;
      vif.drv_cb.WDOGRESn  <= item.wdogresn;
      vif.drv_cb.ECOREVNUM <= item.ecorevnum;
      @(vif.drv_cb);
      seq_item_port.item_done(item);
    end
  endtask

  // WDOGRESn is its own async reset domain (TRM Table 4-24) -- exposed as a
  // direct task, same pattern as wdog_apb_driver.do_reset(), for
  // independent-reset-domain tests (GAP-5 style). Callable again mid-test,
  // but never concurrently with another live writer of WDOGRESn -- see the
  // run_phase comment above.
  task do_reset(int unsigned cycles = 4);
    vif.drv_cb.WDOGRESn <= 1'b0;
    repeat (cycles) @(vif.drv_cb);
    vif.drv_cb.WDOGRESn <= 1'b1;
    @(vif.drv_cb);
  endtask

endclass : wdog_domain_driver
