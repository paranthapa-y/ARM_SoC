class wdog_apb_sequencer extends uvm_sequencer #(wdog_apb_item);
  `uvm_component_utils(wdog_apb_sequencer)
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
endclass : wdog_apb_sequencer
