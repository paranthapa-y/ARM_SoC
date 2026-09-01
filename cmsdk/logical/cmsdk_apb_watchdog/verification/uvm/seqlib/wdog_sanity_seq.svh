//----------------------------------------------------------------------------- 
// End-to-end sanity sequence.
// Generates RAL transactions to unlock the watchdog, program a short timeout,
// enable interrupt and reset, wait for the first timeout, read WDOGRIS, clear
// and reload the watchdog, then wait through two unserviced timeout intervals
// and read WDOGRIS again. This sequence relies on the DUT initial state.
//----------------------------------------------------------------------------- 
class wdog_sanity_seq extends wdog_reg_base_seq;

  `uvm_object_utils(wdog_sanity_seq)

  function new(string name = "wdog_sanity_seq");
    super.new(name);
  endfunction

  task body();
    uvm_status_e   status;
    uvm_reg_data_t rdata;

    if (ral_model == null) begin
      `uvm_fatal(get_type_name(), "RAL model handle is NULL")
    end

    `uvm_info(get_type_name(), "Unlocking watchdog register writes", UVM_LOW)
    ral_model.WDOGLOCK.write(.status(status), .value(32'h1ACCE551), .parent(this));
    if (status != UVM_IS_OK) begin
      `uvm_error(get_type_name(), "WDOGLOCK write failed")
    end

    ral_model.WDOGLOCK.read(.status(status), .value(rdata), .parent(this));
    if (status != UVM_IS_OK) begin
      `uvm_error(get_type_name(), "WDOGLOCK read failed")
    end
    `uvm_info(get_type_name(), $sformatf("WDOGLOCK after unlock = 0x%08h", rdata), UVM_LOW)

    `uvm_info(get_type_name(), "Programming watchdog timeout", UVM_LOW)
    ral_model.WDOGLOAD.write(.status(status), .value(32'h0000_0010), .parent(this));
    if (status != UVM_IS_OK) begin
      `uvm_error(get_type_name(), "WDOGLOAD write failed")
    end

    `uvm_info(get_type_name(), "Enabling watchdog interrupt and reset", UVM_LOW)
    ral_model.WDOGCONTROL.write(.status(status), .value(32'h0000_0003), .parent(this));
    if (status != UVM_IS_OK) begin
      `uvm_error(get_type_name(), "WDOGCONTROL write failed")
    end

    `uvm_info(get_type_name(), "Waiting for first watchdog timeout", UVM_LOW)
    #2000ns;

    ral_model.WDOGRIS.read(.status(status), .value(rdata), .parent(this));
    if (status != UVM_IS_OK) begin
      `uvm_error(get_type_name(), "WDOGRIS read failed")
    end
    `uvm_info(get_type_name(), $sformatf("WDOGRIS after first timeout = 0x%08h", rdata), UVM_LOW)

    `uvm_info(get_type_name(), "Clearing watchdog interrupt", UVM_LOW)
    ral_model.WDOGINTCLR.write(.status(status), .value(32'h0000_0000), .parent(this));
    if (status != UVM_IS_OK) begin
      `uvm_error(get_type_name(), "WDOGINTCLR write failed")
    end

    ral_model.WDOGLOAD.write(.status(status), .value(32'h0000_0010), .parent(this));
    if (status != UVM_IS_OK) begin
      `uvm_error(get_type_name(), "WDOGLOAD reload failed")
    end

    `uvm_info(get_type_name(), "Waiting for consecutive unserviced watchdog timeouts", UVM_LOW)
    #4000ns;

    ral_model.WDOGRIS.read(.status(status), .value(rdata), .parent(this));
    if (status != UVM_IS_OK) begin
      `uvm_error(get_type_name(), "WDOGRIS read failed")
    end
    `uvm_info(get_type_name(), $sformatf("WDOGRIS after unserviced timeouts = 0x%08h", rdata), UVM_LOW)
  endtask

endclass : wdog_sanity_seq
