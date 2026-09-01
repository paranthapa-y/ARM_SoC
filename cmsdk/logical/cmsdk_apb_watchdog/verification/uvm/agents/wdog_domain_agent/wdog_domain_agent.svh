class wdog_domain_agent extends uvm_agent;

  `uvm_component_utils(wdog_domain_agent)

  wdog_domain_driver    driver;
  wdog_domain_sequencer sequencer;
  wdog_domain_monitor   monitor;

  uvm_analysis_port #(wdog_domain_item) ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    monitor = wdog_domain_monitor::type_id::create("monitor", this);
    if (is_active == UVM_ACTIVE) begin
      driver    = wdog_domain_driver::type_id::create("driver", this);
      sequencer = wdog_domain_sequencer::type_id::create("sequencer", this);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    ap = monitor.ap;
    if (is_active == UVM_ACTIVE)
      driver.seq_item_port.connect(sequencer.seq_item_export);
  endfunction

endclass : wdog_domain_agent
