//----------------------------------------------------------------------------- 
// Reset/default-state sequence.
// Generates APB reads of WDOGLOAD, WDOGVALUE, WDOGCONTROL, WDOGRIS, WDOGMIS,
// WDOGLOCK, and WDOGITCR after reset, covering the documented reset values.
//----------------------------------------------------------------------------- 
class wdog_reset_seq extends wdog_reg_base_seq;
  `uvm_object_utils(wdog_reset_seq)

  function new(string name = "wdog_reset_seq");
    super.new(name);
  endfunction

  task body();
    uvm_status_e status;
    uvm_reg_data_t rdata;

    if (ral_model == null) begin
      `uvm_fatal(get_type_name(), "RAL model handle is NULL")
    end

    `uvm_info(get_type_name(), "Checking reset/default state (WDOG_RST_01..07)", UVM_LOW)

    ral_model.WDOGLOAD.read(.status(status), .value(rdata), .parent(this));
    `uvm_info(get_type_name(), $sformatf("WDOGLOAD after reset = 0x%08h", rdata), UVM_LOW)

    ral_model.WDOGVALUE.read(.status(status), .value(rdata), .parent(this));
    `uvm_info(get_type_name(), $sformatf("WDOGVALUE after reset = 0x%08h", rdata), UVM_LOW)

    ral_model.WDOGCONTROL.read(.status(status), .value(rdata), .parent(this));
    `uvm_info(get_type_name(), $sformatf("WDOGCONTROL after reset = 0x%08h", rdata), UVM_LOW)

    ral_model.WDOGRIS.read(.status(status), .value(rdata), .parent(this));
    `uvm_info(get_type_name(), $sformatf("WDOGRIS after reset = 0x%08h", rdata), UVM_LOW)

    ral_model.WDOGMIS.read(.status(status), .value(rdata), .parent(this));
    `uvm_info(get_type_name(), $sformatf("WDOGMIS after reset = 0x%08h", rdata), UVM_LOW)

    ral_model.WDOGLOCK.read(.status(status), .value(rdata), .parent(this));
    `uvm_info(get_type_name(), $sformatf("WDOGLOCK after reset = 0x%08h", rdata), UVM_LOW)

    ral_model.WDOGITCR.read(.status(status), .value(rdata), .parent(this));
    `uvm_info(get_type_name(), $sformatf("WDOGITCR after reset = 0x%08h", rdata), UVM_LOW)
  endtask
endclass : wdog_reset_seq
