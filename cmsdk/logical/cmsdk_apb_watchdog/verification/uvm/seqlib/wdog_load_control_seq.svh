//----------------------------------------------------------------------------- 
// Load/control validation sequence.
// Generates RAL writes and reads for WDOGLOCK, WDOGLOAD, and WDOGCONTROL,
// waits while the watchdog counts, then reads WDOGVALUE and WDOGRIS. It checks
// timeout-load programming and interrupt enable/disable control behavior.
//----------------------------------------------------------------------------- 
class wdog_load_control_seq extends wdog_reg_base_seq;
  `uvm_object_utils(wdog_load_control_seq)

  function new(string name = "wdog_load_control_seq");
    super.new(name);
  endfunction

  task body();
    uvm_status_e status;
    uvm_reg_data_t rdata;

    if (ral_model == null) begin
      `uvm_fatal(get_type_name(), "RAL model handle is NULL")
    end

    `uvm_info(get_type_name(), "Running load/control checks (WDOG_LOAD_01..04, WDOG_CTRL_01..05)", UVM_LOW)

    ral_model.WDOGLOCK.write(.status(status), .value(32'h1ACCE551), .parent(this));
    ral_model.WDOGLOAD.write(.status(status), .value(32'h0000_0010), .parent(this));
    ral_model.WDOGLOAD.read(.status(status), .value(rdata), .parent(this));
    `uvm_info(get_type_name(), $sformatf("WDOGLOAD final writeback = 0x%08h", rdata), UVM_LOW)

    ral_model.WDOGCONTROL.write(.status(status), .value(32'h0000_0001), .parent(this));
    ral_model.WDOGCONTROL.read(.status(status), .value(rdata), .parent(this));
    `uvm_info(get_type_name(), $sformatf("WDOGCONTROL after INTEN=1 = 0x%08h", rdata), UVM_LOW)

    #3000ns;

    ral_model.WDOGVALUE.read(.status(status), .value(rdata), .parent(this));
    `uvm_info(get_type_name(), $sformatf("WDOGVALUE while counting = 0x%08h", rdata), UVM_LOW)

    ral_model.WDOGRIS.read(.status(status), .value(rdata), .parent(this));
    `uvm_info(get_type_name(), $sformatf("WDOGRIS while counting = 0x%08h", rdata), UVM_LOW)

    ral_model.WDOGCONTROL.write(.status(status), .value(32'h0000_0000), .parent(this));
    ral_model.WDOGCONTROL.read(.status(status), .value(rdata), .parent(this));
    `uvm_info(get_type_name(), $sformatf("WDOGCONTROL after INTEN=0 = 0x%08h", rdata), UVM_LOW)
  endtask
endclass : wdog_load_control_seq
