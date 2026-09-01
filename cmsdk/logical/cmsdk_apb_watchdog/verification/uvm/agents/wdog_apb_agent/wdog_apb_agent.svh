class wdog_apb_agent extends uvm_agent;

  `uvm_component_utils(wdog_apb_agent)

  wdog_apb_driver    driver;
  wdog_apb_sequencer sequencer;
  wdog_apb_monitor   monitor;

  uvm_analysis_port #(wdog_apb_item) ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    monitor = wdog_apb_monitor::type_id::create("monitor", this);
    if (is_active == UVM_ACTIVE) begin
      driver    = wdog_apb_driver::type_id::create("driver", this);
      sequencer = wdog_apb_sequencer::type_id::create("sequencer", this);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    ap = monitor.ap;
    if (is_active == UVM_ACTIVE)
      driver.seq_item_port.connect(sequencer.seq_item_export);
  endfunction

endclass : wdog_apb_agent
