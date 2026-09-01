//----------------------------------------------------------------------------- 
// Lock/unlock test.
// Resets the DUT and runs wdog_lock_seq to verify the unlock path, register
// write access while unlocked, write blocking while locked, and lock status.
//----------------------------------------------------------------------------- 
class wdog_lock_test extends wdog_base_test;
  `uvm_component_utils(wdog_lock_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    wdog_lock_seq seq;
    phase.raise_objection(this);
    reset_dut();
    seq = wdog_lock_seq::type_id::create("seq");
    seq.ral_model = env.ral_model;
    seq.start(env.apb_agent.sequencer);
    phase.drop_objection(this);
  endtask
endclass : wdog_lock_test
