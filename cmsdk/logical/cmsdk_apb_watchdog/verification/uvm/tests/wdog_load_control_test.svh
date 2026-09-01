//----------------------------------------------------------------------------- 
// Load and control register test.
// Resets the DUT and runs wdog_load_control_seq to verify timeout-load
// programming, interrupt enable/disable control, counter activity, and raw
// interrupt status during a watchdog interval.
//----------------------------------------------------------------------------- 
class wdog_load_control_test extends wdog_base_test;
  `uvm_component_utils(wdog_load_control_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    wdog_load_control_seq seq;
    phase.raise_objection(this);
    reset_dut();
    seq = wdog_load_control_seq::type_id::create("seq");
    seq.ral_model = env.ral_model;
    seq.start(env.apb_agent.sequencer);
    phase.drop_objection(this);
  endtask
endclass : wdog_load_control_test
