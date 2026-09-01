//----------------------------------------------------------------------------- 
// Common base test class.
// Builds the watchdog UVM environment, provides the common APB/domain reset
// helper, and prints the topology. Scenario tests derive from this class and
// supply the sequence that defines their functional stimulus.
//----------------------------------------------------------------------------- 
class wdog_base_test extends uvm_test;

  `uvm_component_utils(wdog_base_test)

  wdog_env env;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = wdog_env::type_id::create("env", this);
  endfunction

  task reset_dut();
    if (env == null || env.apb_agent == null || env.apb_agent.driver == null)
      return;

    env.apb_agent.driver.do_reset();
    if (env.wdog_agent != null && env.wdog_agent.driver != null)
      env.wdog_agent.driver.do_reset();
  endtask

  function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    uvm_top.print_topology();
  endfunction

endclass : wdog_base_test
