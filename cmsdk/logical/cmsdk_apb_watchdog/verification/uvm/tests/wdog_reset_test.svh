//----------------------------------------------------------------------------- 
// Reset/default-state test.
// Resets the DUT and runs wdog_reset_seq to verify documented reset values for
// the watchdog load, counter, control, interrupt, lock, and integration-mode
// registers.
//----------------------------------------------------------------------------- 
class wdog_reset_test extends wdog_base_test;
  `uvm_component_utils(wdog_reset_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    wdog_reset_seq seq;
    phase.raise_objection(this);
    reset_dut();
    seq = wdog_reset_seq::type_id::create("seq");
    seq.ral_model = env.ral_model;
    seq.start(env.apb_agent.sequencer);
    phase.drop_objection(this);
  endtask
endclass : wdog_reset_test
