//----------------------------------------------------------------------------- 
// End-to-end sanity test using the RAL-backed sequence.
// Runs wdog_sanity_seq through unlock, configuration, first timeout, interrupt
// service, reload, and consecutive unserviced timeout behavior. Unlike the
// other scenario tests, it does not call reset_dut() before starting.
//----------------------------------------------------------------------------- 
class wdog_sanity_test extends wdog_base_test;

  `uvm_component_utils(wdog_sanity_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    wdog_sanity_seq seq;
    phase.raise_objection(this);

    seq = wdog_sanity_seq::type_id::create("seq");
    seq.ral_model = env.ral_model;
    seq.start(env.apb_agent.sequencer);

    phase.drop_objection(this);
  endtask

endclass : wdog_sanity_test
