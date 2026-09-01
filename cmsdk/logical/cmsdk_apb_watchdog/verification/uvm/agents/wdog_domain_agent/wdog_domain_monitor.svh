//-----------------------------------------------------------------------------
// Samples every WDOGCLK edge and publishes what was commanded alongside
// what the DUT produced. This is the sole feed for the scoreboard's live
// (time-evolving) counter model -- see the conversation's RM+SB discussion:
// a per-write reactive model can't predict WDOGVALUE/WDOGINT/WDOGRES, only
// a model that ticks alongside WDOGCLK can.
//-----------------------------------------------------------------------------
class wdog_domain_monitor extends uvm_monitor;

  `uvm_component_utils(wdog_domain_monitor)

  virtual wdog_domain_if.MONITOR vif;
  uvm_analysis_port #(wdog_domain_item) ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual wdog_domain_if.MONITOR)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "wdog_domain_monitor: virtual interface not set")
  endfunction

  task run_phase(uvm_phase phase);
    forever begin
      wdog_domain_item item = wdog_domain_item::type_id::create("item");
      @(vif.mon_cb);
      item.wdogclken = vif.mon_cb.WDOGCLKEN;
      item.wdogresn  = vif.mon_cb.WDOGRESn;
      item.ecorevnum = vif.mon_cb.ECOREVNUM;
      item.wdogint   = vif.mon_cb.WDOGINT;
      item.wdogres   = vif.mon_cb.WDOGRES;
      `uvm_info("WDOG_MON", item.convert2string(), UVM_HIGH)
      ap.write(item);
    end
  endtask

endclass : wdog_domain_monitor
