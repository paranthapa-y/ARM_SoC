//----------------------------------------------------------------------------- 
// Interrupt flow test.
// Resets the DUT and runs wdog_interrupt_flow_seq to verify first-timeout
// interrupt assertion followed by interrupt clearing, reload, and a second
// timeout interval.
//----------------------------------------------------------------------------- 
class wdog_interrupt_flow_test extends wdog_base_test;
  `uvm_component_utils(wdog_interrupt_flow_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    wdog_interrupt_flow_seq seq;
    phase.raise_objection(this);
    reset_dut();
    seq = wdog_interrupt_flow_seq::type_id::create("seq");
    seq.ral_model = env.ral_model;
    seq.start(env.apb_agent.sequencer);
    phase.drop_objection(this);
  endtask
endclass : wdog_interrupt_flow_test
