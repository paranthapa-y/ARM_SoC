//----------------------------------------------------------------------------- 
// WDOGVALUE counter test.
// Resets the DUT and runs wdog_value_seq to verify that WDOGVALUE changes after
// enabling the watchdog and continues to reflect countdown progress.
//----------------------------------------------------------------------------- 
class wdog_value_test extends wdog_base_test;
  `uvm_component_utils(wdog_value_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    wdog_value_seq seq;
    phase.raise_objection(this);
    reset_dut();
    seq = wdog_value_seq::type_id::create("seq");
    seq.ral_model = env.ral_model;
    seq.start(env.apb_agent.sequencer);
    phase.drop_objection(this);
  endtask
endclass : wdog_value_test
