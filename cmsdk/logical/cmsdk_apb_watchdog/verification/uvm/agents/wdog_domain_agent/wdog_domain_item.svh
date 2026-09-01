//-----------------------------------------------------------------------------
// Two distinct roles share this agent, both scoped to the WDOGCLK domain:
//  - as a STIMULUS item (driven by wdog_domain_driver): sets WDOGCLKEN /
//    WDOGRESn / ECOREVNUM for directed CDC-gating and reset-domain tests.
//  - as a MONITOR snapshot (produced by wdog_domain_monitor every WDOGCLK
//    edge): what the driver commanded plus what the DUT actually output,
//    which is what the scoreboard's live counter model consumes.
//-----------------------------------------------------------------------------
class wdog_domain_item extends uvm_sequence_item;

  rand bit        wdogclken;
  rand bit        wdogresn;
  rand bit [3:0]  ecorevnum;

  bit             wdogint;   // monitor-only fields, unused when driving
  bit             wdogres;

  `uvm_object_utils_begin(wdog_domain_item)
    `uvm_field_int(wdogclken, UVM_ALL_ON)
    `uvm_field_int(wdogresn,  UVM_ALL_ON)
    `uvm_field_int(ecorevnum, UVM_ALL_ON)
    `uvm_field_int(wdogint,   UVM_ALL_ON)
    `uvm_field_int(wdogres,   UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "wdog_domain_item");
    super.new(name);
    wdogclken = 1'b1;
    wdogresn  = 1'b1;
  endfunction

  function string convert2string();
    return $sformatf("clken=%0b resn=%0b eco=0x%0h | int=%0b res=%0b",
                      wdogclken, wdogresn, ecorevnum, wdogint, wdogres);
  endfunction

endclass : wdog_domain_item
