//----------------------------------------------------------------------------- 
// Interrupt-flow validation sequence.
// Generates RAL transactions to unlock and configure interrupt+reset operation,
// waits for the first timeout, reads WDOGRIS, clears WDOGINTCLR, reloads
// WDOGLOAD, waits for another timeout, and reads WDOGRIS again.
//----------------------------------------------------------------------------- 
class wdog_interrupt_flow_seq extends wdog_reg_base_seq;
  `uvm_object_utils(wdog_interrupt_flow_seq)

  function new(string name = "wdog_interrupt_flow_seq");
    super.new(name);
  endfunction

  task body();
    uvm_status_e status;
    uvm_reg_data_t rdata;

    if (ral_model == null) begin
      `uvm_fatal(get_type_name(), "RAL model handle is NULL")
    end

    `uvm_info(get_type_name(), "Running interrupt flow checks (WDOG_FLOW_01..04)", UVM_LOW)

    ral_model.WDOGLOCK.write(.status(status), .value(32'h1ACCE551), .parent(this));
    ral_model.WDOGLOAD.write(.status(status), .value(32'h0000_0010), .parent(this));
    ral_model.WDOGCONTROL.write(.status(status), .value(32'h0000_0003), .parent(this));

    #2000ns;

    ral_model.WDOGRIS.read(.status(status), .value(rdata), .parent(this));
    `uvm_info(get_type_name(), $sformatf("WDOGRIS at first timeout = 0x%08h", rdata), UVM_LOW)

    ral_model.WDOGINTCLR.write(.status(status), .value(32'h0000_0000), .parent(this));
    ral_model.WDOGLOAD.write(.status(status), .value(32'h0000_0010), .parent(this));

    #2000ns;

    ral_model.WDOGRIS.read(.status(status), .value(rdata), .parent(this));
    `uvm_info(get_type_name(), $sformatf("WDOGRIS after clear/reload = 0x%08h", rdata), UVM_LOW)
  endtask
endclass : wdog_interrupt_flow_seq
