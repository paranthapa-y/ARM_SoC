class wdog_domain_sequencer extends uvm_sequencer #(wdog_domain_item);
  `uvm_component_utils(wdog_domain_sequencer)
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
endclass : wdog_domain_sequencer
