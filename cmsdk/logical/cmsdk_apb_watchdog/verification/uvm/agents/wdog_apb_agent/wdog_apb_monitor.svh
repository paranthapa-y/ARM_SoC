//-----------------------------------------------------------------------------
// Passively samples the APB bus and broadcasts one wdog_apb_item per
// completed transfer (SETUP+ACCESS with PSEL & PENABLE both high) to the
// scoreboard, independent of whether the driver above is the one that
// generated it -- this is what lets the scoreboard verify what the DUT
// actually did, not just what was requested.
//-----------------------------------------------------------------------------
class wdog_apb_monitor extends uvm_monitor;

  `uvm_component_utils(wdog_apb_monitor)

  virtual wdog_apb_if.MONITOR vif;
  uvm_analysis_port #(wdog_apb_item) ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual wdog_apb_if.MONITOR)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "wdog_apb_monitor: virtual interface not set")
  endfunction

  task run_phase(uvm_phase phase);
    forever begin
      @(vif.mon_cb);
      if (vif.mon_cb.PSEL && vif.mon_cb.PENABLE) begin
        wdog_apb_item item = wdog_apb_item::type_id::create("item");
        item.write = vif.mon_cb.PWRITE;
        item.addr  = vif.mon_cb.PADDR;
        item.wdata = vif.mon_cb.PWDATA;
        item.rdata = vif.mon_cb.PRDATA;
        `uvm_info("APB_MON", item.convert2string(), UVM_HIGH)
        ap.write(item);
      end
    end
  endtask

endclass : wdog_apb_monitor
