class wdog_apb_reg_predictor extends uvm_reg_predictor #(wdog_apb_item);

  `uvm_component_utils(wdog_apb_reg_predictor)

  function new(string name = "wdog_apb_reg_predictor", uvm_component parent);
    super.new(name, parent);
  endfunction

endclass : wdog_apb_reg_predictor