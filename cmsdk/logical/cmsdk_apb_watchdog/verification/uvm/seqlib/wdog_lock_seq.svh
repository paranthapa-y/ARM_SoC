//----------------------------------------------------------------------------- 
// Lock/unlock validation sequence.
// Generates RAL writes that unlock the watchdog, program WDOGLOAD, lock it,
// attempt a protected WDOGLOAD write, and apply the unlock magic value again.
// Reads back WDOGLOAD and WDOGLOCK to observe write protection and lock state.
//----------------------------------------------------------------------------- 
class wdog_lock_seq extends wdog_reg_base_seq;
  `uvm_object_utils(wdog_lock_seq)

  function new(string name = "wdog_lock_seq");
    super.new(name);
  endfunction

  task body();
    uvm_status_e status;
    uvm_reg_data_t rdata;

    if (ral_model == null) begin
      `uvm_fatal(get_type_name(), "RAL model handle is NULL")
    end

    `uvm_info(get_type_name(), "Running lock/unlock / write-blocking checks (WDOG_LOCK_01..06)", UVM_LOW)

    ral_model.WDOGLOCK.write(.status(status), .value(32'h0000_0000), .parent(this));
    ral_model.WDOGLOAD.write(.status(status), .value(32'h0000_0020), .parent(this));
    ral_model.WDOGLOAD.read(.status(status), .value(rdata), .parent(this));
    `uvm_info(get_type_name(), $sformatf("WDOGLOAD after unlock/program = 0x%08h", rdata), UVM_LOW)

    ral_model.WDOGLOCK.write(.status(status), .value(32'h0000_0000), .parent(this));
    ral_model.WDOGLOAD.write(.status(status), .value(32'h0000_0040), .parent(this));
    ral_model.WDOGLOAD.read(.status(status), .value(rdata), .parent(this));
    `uvm_info(get_type_name(), $sformatf("WDOGLOAD while unlocked = 0x%08h", rdata), UVM_LOW)

    ral_model.WDOGLOCK.write(.status(status), .value(32'h0000_0001), .parent(this));
    ral_model.WDOGLOAD.write(.status(status), .value(32'h0000_0080), .parent(this));
    ral_model.WDOGLOAD.read(.status(status), .value(rdata), .parent(this));
    `uvm_info(get_type_name(), $sformatf("WDOGLOAD while locked = 0x%08h", rdata), UVM_LOW)

    ral_model.WDOGLOCK.write(.status(status), .value(32'h1ACCE551), .parent(this));
    ral_model.WDOGLOCK.read(.status(status), .value(rdata), .parent(this));
    `uvm_info(get_type_name(), $sformatf("WDOGLOCK after unlock magic = 0x%08h", rdata), UVM_LOW)
  endtask
endclass : wdog_lock_seq
