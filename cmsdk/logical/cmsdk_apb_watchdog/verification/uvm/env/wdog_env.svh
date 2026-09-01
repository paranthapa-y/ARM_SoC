class wdog_env extends uvm_env;

  `uvm_component_utils(wdog_env)

  wdog_apb_agent    apb_agent;
  wdog_domain_agent wdog_agent;
  wdog_scoreboard   sb;
  register_map      ral_model;
  wdog_apb_reg_adapter    ral_adapter;
  wdog_apb_reg_predictor  ral_predictor;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    apb_agent  = wdog_apb_agent::type_id::create("apb_agent", this);
    wdog_agent = wdog_domain_agent::type_id::create("wdog_agent", this);
    sb         = wdog_scoreboard::type_id::create("sb", this);
    ral_model  = new("ral_model");
    ral_model.build();
    ral_model.lock_model();
    ral_adapter = wdog_apb_reg_adapter::type_id::create("ral_adapter");
    ral_predictor = wdog_apb_reg_predictor::type_id::create("ral_predictor", this);
    // Both agents default to UVM_ACTIVE (uvm_agent's own default) -- the
    // APB agent drives register traffic, the WDOG agent drives
    // WDOGCLKEN/WDOGRESn for directed CDC/reset-domain tests. Both also
    // monitor, which is what feeds the scoreboard regardless of activity.
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    apb_agent.ap.connect(sb.apb_imp);
    apb_agent.ap.connect(ral_predictor.bus_in);
    ral_predictor.map = ral_model.default_map;
    ral_predictor.adapter = ral_adapter;
    ral_model.default_map.set_sequencer(apb_agent.sequencer, ral_adapter);
    wdog_agent.ap.connect(sb.wdog_imp);
  endfunction

endclass : wdog_env
